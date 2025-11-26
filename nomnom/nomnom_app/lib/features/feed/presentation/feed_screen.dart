import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/feed_notifier.dart';
import '../domain/feed_post.dart';
import '../../recipes/presentation/create_recipe_screen.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../groups/presentation/groups_screen.dart';
import '../../groups/presentation/group_detail_screen.dart';
import '../../groups/infrastructure/group_api.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../auth/application/auth_notifier.dart';
import '../../friends/application/friend_notifier.dart';
import 'discover_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(feedNotifierProvider.notifier).loadFeed();
      await ref.read(friendNotifierProvider.notifier).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NomNom Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Discover',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DiscoverScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'My groups',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GroupsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateRecipeScreen(),
            ),
          );
          if (created == true && mounted) {
            await ref.read(feedNotifierProvider.notifier).loadFeed();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(feedNotifierProvider.notifier).loadFeed(),
        child: feedState.isLoading && feedState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : feedState.error != null && feedState.posts.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          feedState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : feedState.posts.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.ramen_dining,
                            size: 72,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your feed is empty',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first recipe, follow other cooks, or join a group to see posts here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: feedState.posts.length,
                        itemBuilder: (context, index) {
                          final post = feedState.posts[index];
                          return FeedPostCardForReuse(post: post);
                        },
                      ),
      ),
    );
  }
}

/// Reusable feed post card used both in main feed and group feed.
class FeedPostCardForReuse extends ConsumerWidget {
  const FeedPostCardForReuse({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendState = ref.watch(friendNotifierProvider);
    final isFollowing =
        friendState.isFollowing(post.authorId);

    Future<void> shareToGroup() async {
      final api = ref.read(groupApiProvider);

      try {
        // Load user's groups
        final groups = await api.getMyGroups();
        if (groups.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are not in any groups yet'),
              ),
            );
          }
          return;
        }

        final selectedId = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    title: Text('Share to group'),
                  ),
                  ...groups.map(
                    (g) => ListTile(
                      title: Text(g.name),
                      subtitle: g.description != null &&
                              g.description!.isNotEmpty
                          ? Text(g.description!)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop(g.id);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (selectedId == null) return;

        await api.sharePostToGroup(
          groupId: selectedId,
          postId: post.id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shared to group'),
            ),
          );
        }
      } catch (e) {
        print('shareToGroup error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not share to group'),
            ),
          );
        }
      }
    }

    return InkWell(
      onTap: post.recipeId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipeId: post.recipeId!,
                    postId: post.id,
                  ),
                ),
              );
            },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + name + (optional) group + follow + time
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: post.authorAvatar != null
                        ? NetworkImage(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null
                        ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (post.groupName != null)
                          InkWell(
                            onTap: post.groupId == null
                                ? null
                                : () {
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            GroupDetailScreen(
                                          groupId:
                                              post.groupId!,
                                          groupName:
                                              post.groupName!,
                                          groupDescription: null,
                                          memberCount: 0,
                                          canJoin: true,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(
                              'in ${post.groupName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    decoration: post.groupId !=
                                            null
                                        ? TextDecoration
                                            .underline
                                        : null,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(friendNotifierProvider.notifier)
                          .toggleFollow(post.authorId);
                    },
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(post.createdAt),
                    style:
                        Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (post.recipeName != null)
                Text(
                  post.recipeName!,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

              if (post.content != null &&
                  post.content!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(post.content!),
                ),

              if (post.recipeImage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.recipeImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.favorite_border),
                    onPressed: () {
                      ref
                          .read(feedNotifierProvider.notifier)
                          .toggleLike(post);
                    },
                  ),
                  Text(post.likeCount.toString()),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline,
                      size: 20),
                  const SizedBox(width: 4),
                  Text(post.commentCount.toString()),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share to group',
                    onPressed: shareToGroup,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

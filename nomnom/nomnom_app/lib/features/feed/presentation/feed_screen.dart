import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/feed_notifier.dart';
import '../domain/feed_post.dart';
import '../infrastructure/feed_api.dart';
import '../../recipes/presentation/create_recipe_screen.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../groups/presentation/groups_screen.dart';
import '../../groups/presentation/group_detail_screen.dart';
import '../../groups/infrastructure/group_api.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/other_user_profile_screen.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/network/dio_client.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _isDiscover = false;
  bool _isDiscoverLoading = false;
  String? _discoverError;
  List<FeedPost> _discoverPosts = [];

  String? _currentUserAvatarUrl;
  bool _isLoadingCurrentUser = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(feedNotifierProvider.notifier).loadFeed();
      await _loadCurrentUserProfile();
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    setState(() {
      _isLoadingCurrentUser = true;
    });

    try {
      final dio = ref.read(authedDioProvider);
      final res = await dio.get('/users/me');
      final data = res.data;

      if (!mounted) return;

      if (data is Map<String, dynamic>) {
        String? _s(dynamic v) {
          if (v == null) return null;
          final s = v.toString().trim();
          return s.isEmpty ? null : s;
        }

        setState(() {
          _currentUserAvatarUrl = _s(
            data['profilePictureUrl'] ??
                data['profilePictureRef'] ??
                data['profileImageUrl'] ??
                data['avatarUrl'] ??
                data['avatar'],
          );
          _isLoadingCurrentUser = false;
        });
      } else {
        setState(() {
          _isLoadingCurrentUser = false;
        });
      }
    } catch (e) {
      print('loadCurrentUserProfile error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCurrentUser = false;
      });
    }
  }

  Future<void> _loadDiscover() async {
    setState(() {
      _isDiscoverLoading = true;
      _discoverError = null;
    });

    try {
      final api = ref.read(feedApiProvider);
      final posts = await api.getDiscoverFeed();
      if (!mounted) return;
      setState(() {
        _discoverPosts = posts;
        _isDiscoverLoading = false;
      });
    } catch (e) {
      print('loadDiscover error: $e');
      if (!mounted) return;
      setState(() {
        _discoverError = 'Could not load discover feed';
        _isDiscoverLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final cs = Theme.of(context).colorScheme;

    final username = currentUser?.username ?? '';
    final initialLetter =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('NomNom'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My groups',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GroupsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
              await _loadCurrentUserProfile();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: cs.surfaceVariant,
                backgroundImage: (!_isLoadingCurrentUser &&
                        _currentUserAvatarUrl != null &&
                        _currentUserAvatarUrl!.isNotEmpty)
                    ? NetworkImage(_currentUserAvatarUrl!)
                    : null,
                child: (_isLoadingCurrentUser ||
                        _currentUserAvatarUrl == null ||
                        _currentUserAvatarUrl!.isEmpty)
                    ? Text(initialLetter)
                    : null,
              ),
            ),
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
            if (_isDiscover) {
              await _loadDiscover();
            } else {
              await ref
                  .read(feedNotifierProvider.notifier)
                  .loadFeed();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _TopToggleChip(
                    label: "What's new",
                    selected: !_isDiscover,
                    onTap: () async {
                      if (_isDiscover) {
                        setState(() => _isDiscover = false);
                        await ref
                            .read(feedNotifierProvider.notifier)
                            .loadFeed();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TopToggleChip(
                    label: 'Discover',
                    selected: _isDiscover,
                    onTap: () async {
                      if (!_isDiscover) {
                        setState(() => _isDiscover = true);
                        await _loadDiscover();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_isDiscover) {
                  await _loadDiscover();
                } else {
                  await ref
                      .read(feedNotifierProvider.notifier)
                      .loadFeed();
                }
              },
              child: _isDiscover
                  ? _buildDiscoverBody(context)
                  : _buildFeedBody(context, feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBody(BuildContext context, FeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const _FeedSkeletonList();
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            feedState.error!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(feedNotifierProvider.notifier)
                  .loadFeed();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (feedState.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 40),
          Icon(Icons.fastfood_outlined, size: 72),
          SizedBox(height: 16),
          Text(
            'No posts yet',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: feedState.posts.length,
      itemBuilder: (context, index) {
        final post = feedState.posts[index];
        return FeedPostCardForReuse(
          post: post,
          currentUserAvatarUrl: _currentUserAvatarUrl,
        );
      },
    );
  }

  Widget _buildDiscoverBody(BuildContext context) {
    if (_isDiscoverLoading && _discoverPosts.isEmpty) {
      return const _FeedSkeletonList();
    }

    if (_discoverError != null && _discoverPosts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _discoverError!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadDiscover,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_discoverPosts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.public,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            "Nothing to discover yet",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'When more people share recipes, they will appear here from all over NomNom.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _discoverPosts.length,
      itemBuilder: (context, index) {
        final post = _discoverPosts[index];
        return FeedPostCardForReuse(
          post: post,
          currentUserAvatarUrl: _currentUserAvatarUrl,
        );
      },
    );
  }
}

class _TopToggleChip extends StatelessWidget {
  const _TopToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: cs.outline.withOpacity(0.4),
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSkeletonList extends StatelessWidget {
  const _FeedSkeletonList();

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final light = Colors.grey.shade200;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 80,
                            decoration: BoxDecoration(
                              color: light,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width:
                      MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 10,
                      width: 40,
                      decoration: BoxDecoration(
                        color: light,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FeedPostCardForReuse extends ConsumerStatefulWidget {
  const FeedPostCardForReuse({
    super.key,
    required this.post,
    this.currentUserAvatarUrl,
  });

  final FeedPost post;
  final String? currentUserAvatarUrl;

  @override
  ConsumerState<FeedPostCardForReuse> createState() =>
      _FeedPostCardForReuseState();
}

class _FeedPostCardForReuseState
    extends ConsumerState<FeedPostCardForReuse> {
  late int _commentCount;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
    _likeCount = widget.post.likeCount;
  }

  @override
  void didUpdateWidget(covariant FeedPostCardForReuse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.commentCount != widget.post.commentCount) {
      _commentCount = widget.post.commentCount;
    }
    if (oldWidget.post.likeCount != widget.post.likeCount) {
      _likeCount = widget.post.likeCount;
    }
  }

  Future<void> _openRecipeDetailAndRefresh(WidgetRef ref) async {
    if (widget.post.recipeId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipeId: widget.post.recipeId!,
          postId: widget.post.id,
        ),
      ),
    );

    await ref.read(feedNotifierProvider.notifier).loadFeed();
  }

  Future<void> _openCommentSheet(WidgetRef ref) async {
    if (widget.post.id.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CommentSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          if (!mounted) return;
          setState(() {
            _commentCount++;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.id;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final avatarUrl =
        (currentUserId != null &&
                widget.post.authorId == currentUserId &&
                widget.currentUserAvatarUrl != null &&
                widget.currentUserAvatarUrl!.isNotEmpty)
            ? widget.currentUserAvatarUrl
            : widget.post.authorAvatar;

    final recipeName = widget.post.recipeName;
    final content = widget.post.content ?? '';

    Future<void> shareToGroup() async {
      final api = ref.read(groupApiProvider);

      try {
        final result =
            await showDialog<_ShareTarget>(context: context, builder: (ctx) {
          return _ShareToGroupDialog(postId: widget.post.id);
        });

        if (result == null) return;
        await api.sharePostToGroup(
          groupId: result.groupId,
          postId: widget.post.id,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Shared to group "${result.groupName}"'),
          ),
        );
      } catch (e) {
        print('shareToGroup error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share to group'),
          ),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (currentUserId != null &&
                        currentUserId == widget.post.authorId) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfileScreen(
                            userId: widget.post.authorId,
                            initialUsername: widget.post.authorName,
                            initialAvatarUrl:
                                widget.post.authorAvatar ?? '',
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.surfaceVariant,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            widget.post.authorName.isNotEmpty
                                ? widget.post.authorName[0]
                                    .toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.post.authorName,
                              style:
                                  textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(widget.post.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (widget.post.groupName != null &&
                          widget.post.groupName!
                              .trim()
                              .isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final groupId = widget.post.groupId;
                            final groupName =
                                widget.post.groupName ?? 'Group';
                            if (groupId == null || groupId.isEmpty) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(
                                  groupId: groupId,
                                  groupName: groupName,
                                  canJoin: false,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'in ${widget.post.groupName}',
                            style:
                                textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((recipeName != null && recipeName.isNotEmpty) ||
                content.isNotEmpty)
              GestureDetector(
                onTap: () => _openRecipeDetailAndRefresh(ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipeName != null &&
                        recipeName.isNotEmpty)
                      Text(
                        recipeName,
                        style:
                            textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (content.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 4.0),
                        child: Text(
                          content,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (widget.post.recipeImage != null &&
                widget.post.recipeImage!.isNotEmpty)
              GestureDetector(
                onTap: () => _openRecipeDetailAndRefresh(ref),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.post.recipeImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
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
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () async {
                    await ref
                        .read(feedNotifierProvider.notifier)
                        .toggleLike(widget.post);
                    await ref
                        .read(feedNotifierProvider.notifier)
                        .loadFeed();
                  },
                ),
                Text(_likeCount.toString()),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _openCommentSheet(ref),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(_commentCount.toString()),
                    ],
                  ),
                ),
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

class _ShareTarget {
  final String groupId;
  final String groupName;

  _ShareTarget({required this.groupId, required this.groupName});
}

class _ShareToGroupDialog extends ConsumerStatefulWidget {
  const _ShareToGroupDialog({required this.postId});

  final String postId;

  @override
  ConsumerState<_ShareToGroupDialog> createState() =>
      _ShareToGroupDialogState();
}

class _ShareToGroupDialogState
    extends ConsumerState<_ShareToGroupDialog> {
  bool _loading = true;
  String? _error;
  List<GroupSummary> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(groupApiProvider);
      final groups = await api.getMyGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      print('loadMyGroups error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your groups';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share to group'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _error != null
              ? SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _groups.isEmpty
                  ? const Text(
                      'You are not a member of any groups yet.',
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      height: 240,
                      child: ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final g = _groups[index];
                          return ListTile(
                            title: Text(g.name),
                            subtitle: g.description != null
                                ? Text(g.description!)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(
                                _ShareTarget(
                                  groupId: g.id,
                                  groupName: g.name,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _FeedComment {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  _FeedComment({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory _FeedComment.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    String authorName = 'Unknown';
    String? avatar;

    if (rawAuthor is Map<String, dynamic>) {
      authorName = rawAuthor['username'] as String? ?? 'Unknown';
      avatar = rawAuthor['profilePictureRef'] as String?;
    }

    return _FeedComment(
      id: json['_id']?.toString() ?? '',
      authorName: authorName,
      authorAvatar: avatar,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(
              json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({
    required this.postId,
    required this.onCommentAdded,
  });

  final String postId;
  final VoidCallback onCommentAdded;

  @override
  ConsumerState<_CommentSheet> createState() =>
      _CommentSheetState();
}

class _CommentSheetState
    extends ConsumerState<_CommentSheet> {
  final TextEditingController _controller =
      TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<_FeedComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(authedDioProvider);
      final res =
          await dio.get('/posts/${widget.postId}/comments');
      final data = res.data;

      final list = data is List
          ? data
          : (data['comments'] as List<dynamic>? ??
              const []);

      final comments = list
          .whereType<Map<String, dynamic>>()
          .map(_FeedComment.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('loadComments error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load comments';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final dio = ref.read(authedDioProvider);
      await dio.post(
        '/posts/${widget.postId}/comments',
        data: {'content': text},
      );

      if (!mounted) return;

      _controller.clear();
      widget.onCommentAdded();
      await _loadComments();

      setState(() {
        _isSending = false;
      });
    } catch (e) {
      print('sendComment error: $e');
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add comment'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comments',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            : _comments.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No comments yet. Be first!',
                                    ),
                                  )
                                : ListView.builder(
                                    controller:
                                        scrollController,
                                    itemCount:
                                        _comments.length,
                                    itemBuilder:
                                        (context, index) {
                                      final c =
                                          _comments[index];
                                      return ListTile(
                                        leading:
                                            CircleAvatar(
                                          backgroundColor:
                                              cs.surfaceVariant,
                                          backgroundImage: (c
                                                          .authorAvatar !=
                                                      null &&
                                                  c.authorAvatar!
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  c.authorAvatar!,
                                                )
                                              : null,
                                          child: (c.authorAvatar ==
                                                      null ||
                                                  c.authorAvatar!
                                                      .isEmpty)
                                              ? Text(
                                                  c.authorName
                                                          .isNotEmpty
                                                      ? c.authorName[
                                                              0]
                                                          .toUpperCase()
                                                      : '?',
                                                )
                                              : null,
                                        ),
                                        title: Text(
                                          c.authorName,
                                          style: textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(c.content),
                                            const SizedBox(
                                                height: 4),
                                            Text(
                                              _formatTime(
                                                  c.createdAt),
                                              style: textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                color: cs
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Add a comment...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            minLines: 1,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: _isSending
                              ? null
                              : _sendComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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

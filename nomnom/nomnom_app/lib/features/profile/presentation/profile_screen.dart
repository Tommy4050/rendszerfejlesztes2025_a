import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../../recipes/infrastructure/recipe_api.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../friends/application/friend_notifier.dart';
import '../../friends/presentation/friends_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  List<RecipeSummary> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
    // Load followers / following for this user
    Future.microtask(() {
      ref.read(friendNotifierProvider.notifier).loadFriends();
    });
  }

  Future<void> _loadMyRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(recipeApiProvider);
      final recipes = await api.getMyRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('getMyRecipes error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your recipes';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final friendState = ref.watch(friendNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMyRecipes();
          await ref
              .read(friendNotifierProvider.notifier)
              .loadFriends();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User header
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? 'Unknown user',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Followers / following counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CountTile(
                  label: 'Following',
                  count: friendState.following.length,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const FriendListScreen(
                                showFollowers: false),
                      ),
                    );
                  },
                ),
                _CountTile(
                  label: 'Followers',
                  count: friendState.followers.length,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const FriendListScreen(
                                showFollowers: true),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'My recipes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (_isLoading && _recipes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _recipes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'You have not created any recipes yet.',
                ),
              )
            else
              ..._recipes.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: r.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.network(
                              r.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.image_not_supported,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.restaurant_menu),
                        ),
                  title: Text(r.name),
                  subtitle: r.cookTimeMin != null
                      ? Text('Cook time: ${r.cookTimeMin} min')
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipeId: r.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.count,
    this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

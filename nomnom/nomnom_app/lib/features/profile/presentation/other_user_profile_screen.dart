import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../friends/application/friend_notifier.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.initialUsername,
    this.initialAvatarUrl,
  });

  final String userId;
  final String? initialUsername;
  final String? initialAvatarUrl;

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  bool _isLoadingProfile = true;
  String? _profileError;

  String? _username;
  String? _email;
  String? _bio;
  String? _avatarUrl;

  bool _isLoadingRecipes = true;
  String? _recipesError;
  List<_UserRecipeSummary> _recipes = [];

  @override
  void initState() {
    super.initState();
    _username = widget.initialUsername;
    _avatarUrl = widget.initialAvatarUrl;
    _loadUser();
    _loadUserRecipes();
    Future.microtask(() {
      ref.read(friendNotifierProvider.notifier).loadFriends();
    });
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final dio = ref.read(authedDioProvider);
      // GET /api/users/:id
      final res = await dio.get('/users/${widget.userId}');
      final data = res.data;

      if (!mounted) return;

      if (data is Map<String, dynamic>) {
        String? s(dynamic v) {
          if (v == null) return null;
          final str = v.toString().trim();
          return str.isEmpty ? null : str;
        }

        setState(() {
          _username = s(data['username']) ?? _username;
          _email = s(data['email']);
          _bio = s(data['bio']);
          _avatarUrl = s(
                data['profilePictureUrl'] ??
                    data['profilePictureRef'] ??
                    data['avatarUrl'] ??
                    data['avatar'],
              ) ??
              _avatarUrl;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
          _profileError = 'Could not load user profile';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('load other user error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Could not load user profile';
      });
    }
  }

  Future<void> _loadUserRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null;
    });

    try {
      final dio = ref.read(authedDioProvider);
      // GET /api/recipes/user/:userId
      final res = await dio.get('/recipes/user/${widget.userId}');
      final data = res.data;

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic> && data['recipes'] is List) {
        list = data['recipes'] as List<dynamic>;
      } else {
        list = const [];
      }

      final recipes = list
          .whereType<Map<String, dynamic>>()
          .map(_UserRecipeSummary.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoadingRecipes = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('load user recipes error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingRecipes = false;
        _recipesError = 'Could not load recipes';
      });
    }
  }

  Widget _buildAvatar({double radius = 40}) {
    final url = _avatarUrl ?? widget.initialAvatarUrl;

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }

    final name = _username ?? 'User';

    return CircleAvatar(
      radius: radius,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendState = ref.watch(friendNotifierProvider);
    final isFollowing = friendState.isFollowing(widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_username ?? 'User'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUser();
          await _loadUserRecipes();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? 'Unknown user',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      if (_email != null)
                        Text(
                          _email!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      if (_bio != null && _bio!.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _bio!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ),
                      if (_isLoadingProfile)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      if (_profileError != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _profileError!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(friendNotifierProvider.notifier)
                      .toggleFollow(widget.userId);
                },
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Public recipes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isLoadingRecipes && _recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recipesError != null && _recipes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _recipesError!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'This user has not shared any recipes yet.',
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
                              errorBuilder:
                                  (_, __, ___) =>
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

class _UserRecipeSummary {
  final String id;
  final String name;
  final int? cookTimeMin;
  final String? imageUrl;

  _UserRecipeSummary({
    required this.id,
    required this.name,
    this.cookTimeMin,
    this.imageUrl,
  });

  factory _UserRecipeSummary.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    String? firstImage;
    if (imagesRaw is List && imagesRaw.isNotEmpty) {
      firstImage = imagesRaw.first?.toString();
    }

    return _UserRecipeSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      cookTimeMin: json['cookTimeMin'] is num
          ? (json['cookTimeMin'] as num).toInt()
          : null,
      imageUrl: firstImage,
    );
  }
}

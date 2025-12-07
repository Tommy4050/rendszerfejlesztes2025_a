import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_notifier.dart';
import '../../recipes/infrastructure/recipe_api.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../friends/application/friend_notifier.dart';
import '../../friends/presentation/friends_list_screen.dart';
import '../../../core/network/dio_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoadingRecipes = true;
  String? _recipesError;
  List<RecipeSummary> _recipes = [];

  String? _bio;
  String? _avatarUrl;
  File? _avatarFile;

  bool _isLoadingProfile = false;
  String? _profileError;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
    _loadProfileInfo();

    Future.microtask(() {
      ref.read(friendNotifierProvider.notifier).loadFriends();
    });
  }

  Future<void> _loadMyRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null;
    });

    try {
      final api = ref.read(recipeApiProvider);
      final recipes = await api.getMyRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoadingRecipes = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('getMyRecipes error: $e');
      if (!mounted) return;
      setState(() {
        _recipesError = 'Could not load your recipes';
        _isLoadingRecipes = false;
      });
    }
  }

  Future<void> _loadProfileInfo() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final dio = ref.read(authedDioProvider);
      // GET /users/me
      final response = await dio.get('/users/me');
      final data = response.data;

      if (!mounted) return;

      if (data is Map<String, dynamic>) {
        String? _string(dynamic v) =>
            v == null ? null : v.toString().trim().isEmpty ? null : v.toString();

        setState(() {
          _bio = _string(data['bio']);
          _avatarUrl = _string(
            data['profilePictureUrl'] ??
                data['profileImageUrl'] ??
                data['avatarUrl'] ??
                data['avatar'],
          );
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('loadProfileInfo error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Could not load profile info';
      });
    }
  }

  Future<void> _saveProfileChanges(String? newBio) async {
    final dio = ref.read(authedDioProvider);

    String? uploadedUrl = _avatarUrl;

    if (_avatarFile != null) {
      try {
        final fileName = _avatarFile!.path.split('/').last;
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            _avatarFile!.path,
            filename: fileName,
          ),
        });

        final uploadResp = await dio.post(
          '/uploads/image',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        final uploadData = uploadResp.data;
        if (uploadData is Map<String, dynamic>) {
          final url = (uploadData['url'] ??
                  uploadData['secure_url'] ??
                  uploadData['imageUrl'])
              ?.toString();
          if (url != null && url.isNotEmpty) {
            uploadedUrl = url;
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('upload profile image error: $e');
      }
    }

    final payload = <String, dynamic>{};
    if (newBio != null) {
      payload['bio'] = newBio;
    }
    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      payload['profilePictureUrl'] = uploadedUrl;
    }

    if (payload.isEmpty) return;

    await dio.patch('/users/me', data: payload);

    if (!mounted) return;
    setState(() {
      _bio = newBio ?? _bio;
      _avatarUrl = uploadedUrl ?? _avatarUrl;
      _avatarFile = null;
    });
  }

  Widget _buildAvatar({double radius = 28}) {
    if (_avatarFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_avatarFile!),
      );
    }

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person, size: 32),
    );
  }

  void _openEditProfile() {
    bool saving = false;
    String tempBio = _bio ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              Future<void> pickNewPhoto() async {
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked == null) return;

                setState(() {
                  _avatarFile = File(picked.path);
                });
                setModalState(() {});
              }

              Future<void> save() async {
                final newBio = tempBio.trim().isEmpty
                    ? null
                    : tempBio.trim();

                setModalState(() {
                  saving = true;
                });

                try {
                  await _saveProfileChanges(newBio);
                  if (!mounted) return;

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                    ),
                  );
                } catch (e) {
                  // ignore: avoid_print
                  print('save profile error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not update profile'),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setModalState(() {
                      saving = false;
                    });
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(radius: 28),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: saving ? null : pickNewPhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Change photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: tempBio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell others a bit about you',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      tempBio = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: saving ? null : save,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final friendState = ref.watch(friendNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfile,
            tooltip: 'Edit profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMyRecipes();
          await _loadProfileInfo();
          await ref
              .read(friendNotifierProvider.notifier)
              .loadFriends();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                      if (_bio != null && _bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
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
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      if (_profileError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
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
                          showFollowers: false,
                        ),
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
                          showFollowers: true,
                        ),
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

            if (_isLoadingRecipes && _recipes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recipesError != null &&
                _recipes.isEmpty)
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
                  'You have not created any recipes yet.',
                ),
              )
            else
              ..._recipes.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: r.imageUrl != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: Image.network(
                            r.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image_not_supported,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long),
                        ),
                  title: Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: r.cookTimeMin != null
                      ? Text('${r.cookTimeMin} min')
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
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _CountTile({
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
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
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
      ),
    );
  }
}

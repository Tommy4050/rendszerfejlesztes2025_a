import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class FriendUser {
  final String id;
  final String username;
  final String? avatarUrl;

  const FriendUser({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['profilePictureRef'] as String?,
    );
  }
}

final friendApiProvider = Provider<FriendApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return FriendApi(dio);
});

class FriendApi {
  final Dio _dio;
  FriendApi(this._dio);

  Future<List<FriendUser>> getFollowers() async {
    final response = await _dio.get('/friends/followers');
    return _extractUserList(response.data, 'followers');
  }

  Future<List<FriendUser>> getFollowing() async {
    final response = await _dio.get('/friends/following');
    return _extractUserList(response.data, 'following');
  }

  Future<void> followUser(String userId) async {
    await _dio.post('/friends/$userId/follow');
  }

  Future<void> unfollowUser(String userId) async {
    await _dio.post('/friends/$userId/unfollow');
  }

  List<FriendUser> _extractUserList(dynamic data, String key) {
    if (data is Map<String, dynamic>) {
      final list = (data['users'] ?? data[key] ?? []) as List<dynamic>;
      return list
          .map((e) => FriendUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is List) {
      return data
          .map((e) => FriendUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return const [];
  }
}

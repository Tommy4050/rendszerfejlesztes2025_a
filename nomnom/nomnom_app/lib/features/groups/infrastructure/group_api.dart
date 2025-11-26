import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../feed/domain/feed_post.dart';

final groupApiProvider = Provider<GroupApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return GroupApi(dio);
});

class GroupSummary {
  final String id;
  final String name;
  final String? description;
  final int memberCount;

  GroupSummary({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class GroupApi {
  final Dio _dio;
  GroupApi(this._dio);

  /// Get groups the current user is a member of.
  Future<List<GroupSummary>> getMyGroups() async {
    final response = await _dio.get('/groups');
    final data = response.data;

    final list = data is List
        ? data
        : (data['groups'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(GroupSummary.fromJson)
        .toList();
  }

  /// Create a new group.
  Future<GroupSummary> createGroup({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post('/groups', data: {
      'name': name,
      'description': description,
    });

    final data = response.data as Map<String, dynamic>;
    final groupJson = (data['group'] as Map<String, dynamic>? ?? data);
    return GroupSummary.fromJson(groupJson);
  }

  /// Join a group (for future use add discovery).
  Future<void> joinGroup(String groupId) async {
    await _dio.post('/groups/$groupId/join');
  }

  /// Get posts in a specific group.
  Future<List<FeedPost>> getGroupPosts(String groupId) async {
    final res = await _dio.get('/groups/$groupId/posts');

    dynamic data = res.data;

    // In case backend sends stringified JSON.
    if (data is String) {
      data = jsonDecode(data) as Map<String, dynamic>;
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected group posts payload: $data');
    }

    final postsJson = data['posts'] as List<dynamic>? ?? const [];

    return postsJson
        .whereType<Map<String, dynamic>>()
        .map(FeedPost.fromJson)
        .toList();
  }

  /// Share an existing post into a group.
  Future<void> sharePostToGroup({
    required String groupId,
    required String postId,
  }) async {
    await _dio.post('/groups/$groupId/share', data: {
      'postId': postId,
    });
  }
}

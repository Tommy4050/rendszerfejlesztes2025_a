import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../feed/domain/feed_post.dart';

final groupApiProvider = Provider<GroupApi>((ref) {
  final dio = ref.read(authedDioProvider);
  return GroupApi(dio);
});

class GroupApi {
  GroupApi(this._dio);

  final Dio _dio;

  /// GET /api/groups - groups current user is a member of
  Future<List<GroupSummary>> getMyGroups() async {
    final res = await _dio.get('/groups');
    final data = res.data;

    final list = data is List
        ? data
        : (data['groups'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(GroupSummary.fromJson)
        .toList();
  }

  /// POST /api/groups - create a new group
  Future<GroupSummary> createGroup({
    required String name,
    String? description,
    String? coverPictureRef,
  }) async {
    final res = await _dio.post(
      '/groups',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (coverPictureRef != null && coverPictureRef.isNotEmpty)
          'coverPictureRef': coverPictureRef,
      },
    );

    final data = res.data as Map<String, dynamic>;
    final groupJson =
        (data['group'] as Map<String, dynamic>? ?? data);

    return GroupSummary.fromJson(groupJson);
  }

  /// GET /api/groups/:id/posts - group details + posts
  Future<GroupPostsResponse> getGroupPosts(String groupId) async {
    final res = await _dio.get('/groups/$groupId/posts');
    final data = res.data as Map<String, dynamic>;

    final groupJson =
        (data['group'] as Map<String, dynamic>? ?? const {});
    final postsJson =
        (data['posts'] as List<dynamic>? ?? const []);

    final group = GroupSummary.fromJson(groupJson);
    final posts = postsJson
        .whereType<Map<String, dynamic>>()
        .map(FeedPost.fromJson)
        .toList();

    return GroupPostsResponse(group: group, posts: posts);
  }

  /// POST /api/groups/:id/join
  Future<void> joinGroup(String groupId) async {
    await _dio.post('/groups/$groupId/join');
  }

  /// POST /api/groups/:id/share
  Future<void> sharePostToGroup({
    required String groupId,
    required String postId,
    String? content,
  }) async {
    await _dio.post(
      '/groups/$groupId/share',
      data: {
        'postId': postId,
        if (content != null && content.isNotEmpty) 'content': content,
      },
    );
  }

  /// GET /api/groups/:id/members
  Future<GroupMembersResponse> getGroupMembers(String groupId) async {
    final res = await _dio.get('/groups/$groupId/members');
    final data = res.data as Map<String, dynamic>;

    final membersJson =
        (data['members'] as List<dynamic>? ?? const []);
    final isAdmin = data['isAdmin'] == true;
    final isOwner = data['isOwner'] == true;

    final members = membersJson
        .whereType<Map<String, dynamic>>()
        .map(GroupMemberDto.fromJson)
        .toList();

    return GroupMembersResponse(
      members: members,
      isAdmin: isAdmin,
      isOwner: isOwner,
    );
  }

  Future<GroupSummary> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? coverPictureRef,
  }) async {
    final res = await _dio.patch(
      '/groups/$groupId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (coverPictureRef != null)
          'coverPictureRef': coverPictureRef,
      },
    );

    final data = res.data as Map<String, dynamic>;
    final groupJson =
        (data['group'] as Map<String, dynamic>? ?? data);

    return GroupSummary.fromJson(groupJson);
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String role, // 'member' or 'admin'
  }) async {
    await _dio.patch(
      '/groups/$groupId/members/$userId',
      data: {'role': role},
    );
  }

  /// DELETE /api/groups/:id/members/:userId
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _dio.delete('/groups/$groupId/members/$userId');
  }

  /// DELETE /api/groups/:id/posts/:postId
  Future<void> deleteGroupPost({
    required String groupId,
    required String postId,
  }) async {
    await _dio.delete('/groups/$groupId/posts/$postId');
  }
}

class GroupSummary {
  final String id;
  final String name;
  final String? description;
  final String? coverPictureRef;
  final int memberCount;
  final bool isMember;
  final bool isAdmin;

  GroupSummary({
    required this.id,
    required this.name,
    this.description,
    this.coverPictureRef,
    required this.memberCount,
    required this.isMember,
    required this.isAdmin,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();

    return GroupSummary(
      id: id,
      name: json['name']?.toString() ?? 'Unnamed group',
      description: json['description']?.toString(),
      coverPictureRef: json['coverPictureRef']?.toString(),
      memberCount: json['memberCount'] is num
          ? (json['memberCount'] as num).toInt()
          : 0,
      isMember: json['isMember'] == true,
      isAdmin: json['isAdmin'] == true,
    );
  }
}

class GroupPostsResponse {
  final GroupSummary group;
  final List<FeedPost> posts;

  GroupPostsResponse({
    required this.group,
    required this.posts,
  });
}

class GroupMemberDto {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role; // 'admin' or 'member'

  GroupMemberDto({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.role,
  });

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>? ?? const {});
    final id = (user['_id'] ?? '').toString();
    final username = user['username']?.toString() ?? 'Unknown';
    final avatar = (user['profilePictureRef'] ??
            user['profilePictureUrl'] ??
            user['avatarUrl'])
        ?.toString();

    final role = json['role']?.toString() ?? 'member';

    return GroupMemberDto(
      userId: id,
      username: username,
      avatarUrl: avatar,
      role: role,
    );
  }

  GroupMemberDto copyWith({
    String? username,
    String? avatarUrl,
    String? role,
  }) {
    return GroupMemberDto(
      userId: userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}

class GroupMembersResponse {
  final List<GroupMemberDto> members;
  final bool isAdmin;
  final bool isOwner;

  GroupMembersResponse({
    required this.members,
    required this.isAdmin,
    required this.isOwner,
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

final commentApiProvider = Provider<CommentApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return CommentApi(dio);
});

class PostComment {
  final String id;
  final String content;
  final String authorName;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return PostComment(
      id: json['_id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      authorName: author?['username'] as String? ?? 'Unknown',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CommentApi {
  final Dio _dio;
  CommentApi(this._dio);

  Future<List<PostComment>> getComments(String postId) async {
    final response = await _dio.get('/posts/$postId/comments');
    final data = response.data as Map<String, dynamic>;
    final list = data['comments'] as List<dynamic>? ?? [];

    return list
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostComment> addComment(String postId, String content) async {
    final response = await _dio.post(
      '/posts/$postId/comments',
      data: {'content': content},
    );
    final data = response.data as Map<String, dynamic>;
    return PostComment.fromJson(data['comment'] as Map<String, dynamic>);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/feed_post.dart';

final feedApiProvider = Provider<FeedApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return FeedApi(dio);
});

class FeedApi {
  final Dio _dio;
  FeedApi(this._dio);

  Future<List<FeedPost>> getFeed() async {
    final res = await _dio.get('/feed');
    final data = res.data;

    final list = data is List
        ? data
        : (data['posts'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedPost.fromJson)
        .toList();
  }

  Future<List<FeedPost>> getDiscoverFeed() async {
    final res = await _dio.get('/feed/discover');
    final data = res.data;

    final list = data is List
        ? data
        : (data['posts'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedPost.fromJson)
        .toList();
  }

  Future<void> likePost(String postId) async {
    await _dio.post('/posts/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await _dio.post('/posts/$postId/unlike');
  }
}

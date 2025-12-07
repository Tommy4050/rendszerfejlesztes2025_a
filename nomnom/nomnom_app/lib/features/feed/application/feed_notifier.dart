import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_post.dart';
import '../infrastructure/feed_api.dart';

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final api = ref.watch(feedApiProvider);
  return FeedNotifier(api);
});

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedApi _api;

  FeedNotifier(this._api) : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _api.getFeed();
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      print('loadFeed error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load feed',
      );
    }
  }

  Future<void> toggleLike(FeedPost post) async {
    try {
      await _api.likePost(post.id);
    } catch (e) {
      print('likePost error, trying unlikePost: $e');
      try {
        await _api.unlikePost(post.id);
      } catch (e2) {
        print('unlikePost error: $e2');
      }
    }

    await loadFeed();
  }
}

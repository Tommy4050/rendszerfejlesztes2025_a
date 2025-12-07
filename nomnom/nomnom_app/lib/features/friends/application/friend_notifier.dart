import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/friend_api.dart';

class FriendState {
  final List<FriendUser> followers;
  final List<FriendUser> following;
  final bool isLoading;
  final String? error;

  const FriendState({
    this.followers = const [],
    this.following = const [],
    this.isLoading = false,
    this.error,
  });

  FriendState copyWith({
    List<FriendUser>? followers,
    List<FriendUser>? following,
    bool? isLoading,
    String? error,
  }) {
    return FriendState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFollowing(String userId) {
    return following.any((u) => u.id == userId);
  }
}

final friendNotifierProvider =
    StateNotifierProvider<FriendNotifier, FriendState>((ref) {
  final api = ref.watch(friendApiProvider);
  return FriendNotifier(api);
});

class FriendNotifier extends StateNotifier<FriendState> {
  final FriendApi _api;

  FriendNotifier(this._api) : super(const FriendState());

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final followers = await _api.getFollowers();
      final following = await _api.getFollowing();

      state = state.copyWith(
        followers: followers,
        following: following,
        isLoading: false,
      );
    } catch (e) {
      print('loadFriends error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load followers',
      );
    }
  }

  Future<void> toggleFollow(String userId) async {
    final currentlyFollowing = state.isFollowing(userId);

    try {
      if (currentlyFollowing) {
        await _api.unfollowUser(userId);
        state = state.copyWith(
          following:
              state.following.where((u) => u.id != userId).toList(),
        );
      } else {
        await _api.followUser(userId);
        await loadFriends();
      }
    } catch (e) {
      print('toggleFollow error: $e');
      await loadFriends();
    }
  }
}

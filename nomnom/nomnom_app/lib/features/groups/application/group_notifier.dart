import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/group_api.dart';

class GroupsState {
  final List<GroupSummary> groups;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupsState copyWith({
    List<GroupSummary>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final groupsNotifierProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final api = ref.watch(groupApiProvider);
  return GroupsNotifier(api);
});

class GroupsNotifier extends StateNotifier<GroupsState> {
  final GroupApi _api;

  GroupsNotifier(this._api) : super(const GroupsState());

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final groups = await _api.getMyGroups();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      print('loadGroups error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load groups',
      );
    }
  }

  Future<void> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group =
          await _api.createGroup(name: name, description: description);
      state = state.copyWith(groups: [group, ...state.groups]);
    } catch (e) {
      print('createGroup error: $e');
      rethrow;
    }
  }
}

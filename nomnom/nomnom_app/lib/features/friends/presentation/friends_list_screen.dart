import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/friend_notifier.dart';

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({
    super.key,
    required this.showFollowers,
  });

  final bool showFollowers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendNotifierProvider);
    final users =
        showFollowers ? state.followers : state.following;

    return Scaffold(
      appBar: AppBar(
        title: Text(showFollowers ? 'Followers' : 'Following'),
      ),
      body: state.isLoading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Text(
                    showFollowers
                        ? 'No one follows you yet 😅'
                        : 'You are not following anyone yet',
                  ),
                )
              : ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = users[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: u.avatarUrl != null
                            ? NetworkImage(u.avatarUrl!)
                            : null,
                        child: u.avatarUrl == null
                            ? Text(
                                u.username.isNotEmpty
                                    ? u.username[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(u.username),
                    );
                  },
                ),
    );
  }
}

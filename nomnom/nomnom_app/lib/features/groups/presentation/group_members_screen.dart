import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/group_api.dart';
import '../../auth/application/auth_notifier.dart';
import '../../profile/presentation/other_user_profile_screen.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });

  final String groupId;
  final String groupName;
  final bool isAdmin;

  @override
  ConsumerState<GroupMembersScreen> createState() =>
      _GroupMembersScreenState();
}

class _GroupMembersScreenState
    extends ConsumerState<GroupMembersScreen> {
  bool _isLoading = true;
  String? _error;
  bool _changed = false;

  List<GroupMemberDto> _members = [];
  bool _apiThinksAdmin = false;
  bool _apiThinksOwner = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(groupApiProvider);
      final resp = await api.getGroupMembers(widget.groupId);

      if (!mounted) return;

      setState(() {
        _members = resp.members;
        _apiThinksAdmin = resp.isAdmin;
        _apiThinksOwner = resp.isOwner;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('getGroupMembers error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load members';
        _isLoading = false;
      });
    }
  }

  bool get _isAdminEffective =>
      widget.isAdmin || _apiThinksAdmin;

  bool get _isOwnerEffective => _apiThinksOwner;

  Future<void> _changeRole(
    GroupMemberDto member,
    String role,
  ) async {
    try {
      final api = ref.read(groupApiProvider);
      await api.updateMemberRole(
        groupId: widget.groupId,
        userId: member.userId,
        role: role,
      );
      if (!mounted) return;

      setState(() {
        _members = _members
            .map<GroupMemberDto>(
              (m) => m.userId == member.userId
                  ? m.copyWith(role: role)
                  : m,
            )
            .toList();
        _changed = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('updateMemberRole error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not change member role'),
        ),
      );
    }
  }

  Future<void> _removeMember(GroupMemberDto member) async {
    try {
      final api = ref.read(groupApiProvider);
      await api.removeMember(
        groupId: widget.groupId,
        userId: member.userId,
      );
      if (!mounted) return;

      setState(() {
        _members.removeWhere(
          (m) => m.userId == member.userId,
        );
        _changed = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('removeMember error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove member'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.id;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.groupName} members'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadMembers,
          child: _isLoading
              ? ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  itemCount: 8,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildMemberSkeleton();
                  },
                )
              : _error != null
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            _error!,
                            style:
                                const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : _members.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('No members yet.'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = _members[index];
                            final isSelf =
                                m.userId == currentUserId;
                            final isAdminMember =
                                m.role == 'admin';
                            final isOwnerMember =
                                m.role == 'owner';

                            final canShowMenu =
                                _isAdminEffective &&
                                !isSelf &&
                                (
                                  _isOwnerEffective ||
                                  (!isAdminMember && !isOwnerMember)
                                );

                            final subtitle = isOwnerMember
                                ? 'Owner'
                                : (isAdminMember ? 'Admin' : 'Member');

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    m.avatarUrl != null
                                        ? NetworkImage(
                                            m.avatarUrl!,
                                          )
                                        : null,
                                child: m.avatarUrl == null
                                    ? Text(
                                        m.username.isNotEmpty
                                            ? m.username[0]
                                                .toUpperCase()
                                            : '?',
                                      )
                                    : null,
                              ),
                              title: Text(m.username),
                              subtitle: Text(subtitle),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OtherUserProfileScreen(
                                      userId: m.userId,
                                      initialUsername:
                                          m.username,
                                      initialAvatarUrl:
                                          m.avatarUrl,
                                    ),
                                  ),
                                );
                              },
                              trailing: canShowMenu
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value ==
                                            'make_admin') {
                                          _changeRole(
                                            m,
                                            'admin',
                                          );
                                        } else if (value ==
                                            'remove_admin') {
                                          _changeRole(
                                            m,
                                            'member',
                                          );
                                        } else if (value ==
                                            'remove') {
                                          _removeMember(m);
                                        }
                                      },
                                      itemBuilder: (ctx) {
                                        final items =
                                            <PopupMenuEntry<
                                                String>>[];

                                        if (isAdminMember) {
                                          if (_isOwnerEffective) {
                                            items.add(
                                              const PopupMenuItem<
                                                  String>(
                                                value:
                                                    'remove_admin',
                                                child: Text(
                                                    'Remove admin'),
                                              ),
                                            );
                                          }
                                        } else if (!isOwnerMember) {
                                          items.add(
                                            const PopupMenuItem<
                                                String>(
                                              value:
                                                  'make_admin',
                                              child: Text(
                                                  'Make admin'),
                                            ),
                                          );
                                        }

                                        if (!isOwnerMember) {
                                          items.add(
                                            const PopupMenuItem<
                                                String>(
                                              value: 'remove',
                                              child: Text(
                                                  'Remove from group'),
                                            ),
                                          );
                                        }

                                        return items;
                                      },
                                    )
                                  : null,
                            );
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildMemberSkeleton() {
    return ListTile(
      leading: const _SkeletonCircle(size: 40),
      title:
          const _SkeletonLine(width: 140, height: 16),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 4.0),
        child:
            _SkeletonLine(width: 80, height: 12),
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.height,
    this.width,
    this.borderRadius = 12,
  });

  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    this.height = 14,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return _SkeletonBox(
      height: height,
      width: width,
      borderRadius: 999,
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}

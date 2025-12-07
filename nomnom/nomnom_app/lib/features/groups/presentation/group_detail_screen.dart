import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/group_api.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/presentation/feed_screen.dart' show FeedPostCardForReuse;
import 'group_members_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupDescription,
    this.memberCount = 0,
    this.canJoin = true,
  });

  final String groupId;
  final String groupName;
  final String? groupDescription;
  final int memberCount;
  final bool canJoin;

  @override
  ConsumerState<GroupDetailScreen> createState() =>
      _GroupDetailScreenState();
}

class _GroupDetailScreenState
    extends ConsumerState<GroupDetailScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;

  GroupSummary? _group;
  List<FeedPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(groupApiProvider);
      final response = await api.getGroupPosts(widget.groupId);

      if (!mounted) return;

      setState(() {
        _group = response.group;
        _posts = response.posts;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('loadGroup error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load group';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    setState(() {
      _isJoining = true;
    });

    try {
      final api = ref.read(groupApiProvider);
      await api.joinGroup(widget.groupId);
      await _loadGroup();
    } catch (e) {
      // ignore: avoid_print
      print('joinGroup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not join group'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _showEditGroupDialog() async {
    final groupName = _group?.name ?? widget.groupName;
    final groupDescription =
        _group?.description ?? widget.groupDescription;

    final nameController = TextEditingController(text: groupName);
    final descController = TextEditingController(
      text: groupDescription ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final newName = nameController.text.trim();
    final newDesc = descController.text.trim();

    try {
      final api = ref.read(groupApiProvider);
      final updated = await api.updateGroup(
        groupId: widget.groupId,
        name: newName.isEmpty ? null : newName,
        description: newDesc,
      );
      if (!mounted) return;

      setState(() {
        _group = updated;
      });
    } catch (e) {
      // ignore: avoid_print
      print('updateGroup error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update group'),
        ),
      );
    }
  }

  Future<void> _deletePost(FeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text(
            'Are you sure you want to remove this post from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(groupApiProvider);
      await api.deleteGroupPost(
        groupId: widget.groupId,
        postId: post.id,
      );
      if (!mounted) return;

      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });
    } catch (e) {
      // ignore: avoid_print
      print('deleteGroupPost error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete post'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = _group?.name ?? widget.groupName;
    final groupDescription =
        _group?.description ?? widget.groupDescription;
    final memberCount =
        _group?.memberCount ?? widget.memberCount;

    final isMember = _group?.isMember ?? !widget.canJoin;
    final isAdmin = _group?.isAdmin ?? false;
    final hasPosts = _posts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showEditGroupDialog,
              tooltip: 'Edit group',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroup,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.group),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final changed =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GroupMembersScreen(
                                groupId: widget.groupId,
                                groupName: groupName,
                                isAdmin: isAdmin,
                              ),
                            ),
                          );
                          if (changed == true) {
                            await _loadGroup();
                          }
                        },
                        child: Text(
                          '$memberCount member${memberCount == 1 ? '' : 's'}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                decoration:
                                    TextDecoration.underline,
                              ),
                        ),
                      ),
                      if (groupDescription != null &&
                          groupDescription.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0),
                          child: Text(
                            groupDescription,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isMember)
                  ElevatedButton(
                    onPressed:
                        _isJoining ? null : _joinGroup,
                    child: _isJoining
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Join'),
                  )
                else
                  OutlinedButton(
                    onPressed: null,
                    child: const Text('Joined'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Text(
                  'Posts',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading && !hasPosts)
              const _GroupPostsSkeleton()
            else if (_error != null && !hasPosts)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style:
                      const TextStyle(color: Colors.red),
                ),
              )
            else if (!hasPosts && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "No posts in this group yet.\n\n"
                  "Tip: Open the main feed and use the share button "
                  "on a recipe to share it into this group.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Column(
                children: _posts
                    .map((p) => _buildPostCard(p, isAdmin))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(FeedPost post, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedPostCardForReuse(post: post),
        if (isAdmin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _deletePost(post),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove from group'),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _GroupPostsSkeleton extends StatelessWidget {
  const _GroupPostsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: const [
                _SkeletonLine(width: 160, height: 16),
                SizedBox(height: 8),
                _SkeletonLine(
                    width: double.infinity, height: 12),
                SizedBox(height: 4),
                _SkeletonLine(width: 220, height: 12),
              ],
            ),
          ),
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

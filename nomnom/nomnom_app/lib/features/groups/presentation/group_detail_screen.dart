import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/group_api.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/presentation/feed_screen.dart' show FeedPostCardForReuse;

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupDescription,
    required this.memberCount,
    this.canJoin = false,
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
  List<FeedPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  bool _joining = false;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(groupApiProvider);
      final posts = await api.getGroupPosts(widget.groupId);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('getGroupPosts error: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not load group posts';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    setState(() {
      _joining = true;
    });

    try {
      final api = ref.read(groupApiProvider);
      await api.joinGroup(widget.groupId);

      if (!mounted) return;
      setState(() {
        _joining = false;
        _joined = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group')),
      );
    } catch (e) {
      print('joinGroup error: $e');
      if (!mounted) return;
      setState(() {
        _joining = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join group')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPosts = _posts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group header card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            color: Colors.green.shade100,
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.groupName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.memberCount} member${widget.memberCount == 1 ? '' : 's'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.groupDescription != null &&
                        widget.groupDescription!.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.groupDescription!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ),

                    // Join button if this screen was opened in "discover mode"
                    if (widget.canJoin)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _joining
                                ? null
                                : _joinGroup,
                            icon: _joining
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _joined
                                        ? Icons.check
                                        : Icons.group_add,
                                  ),
                            label: Text(
                              _joined ? 'Joined' : 'Join group',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Posts section title
            Row(
              children: [
                Text(
                  'Posts',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_error != null && !hasPosts)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (!hasPosts && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "No posts in this group yet.\n\n"
                  "Tip: Open the main feed and use the share button "
                  "on a recipe to share it into this group.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              )
            else
              ..._posts.map(
                (post) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: FeedPostCardForReuse(post: post),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

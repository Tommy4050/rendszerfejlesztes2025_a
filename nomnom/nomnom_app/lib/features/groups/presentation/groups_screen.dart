import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/group_notifier.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(groupsNotifierProvider.notifier).loadGroups(),
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create group'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Group name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref
                      .read(groupsNotifierProvider.notifier)
                      .createGroup(
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop(true);
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Could not create group'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      await ref.read(groupsNotifierProvider.notifier).loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My groups'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(groupsNotifierProvider.notifier).loadGroups(),
        child: state.isLoading && state.groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.groups.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      return ListTile(
                        title: Text(group.name),
                        subtitle: group.description != null &&
                                group.description!.isNotEmpty
                            ? Text(group.description!)
                            : null,
                        trailing: Text(
                          '${group.memberCount} members',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(
                                groupId: group.id,
                                groupName: group.name,
                                groupDescription: group.description,
                                memberCount: group.memberCount,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

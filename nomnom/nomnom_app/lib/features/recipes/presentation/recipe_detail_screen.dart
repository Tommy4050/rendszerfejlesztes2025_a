import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/recipe_api.dart';
import '../../comments/infrastructure/comment_api.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.postId,
  });

  final String recipeId;
  final String? postId;

  @override
  ConsumerState<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState
    extends ConsumerState<RecipeDetailScreen> {
  RecipeDetail? _recipe;
  bool _isLoading = true;
  String? _error;

  List<PostComment> _comments = [];
  bool _commentsLoading = false;
  String? _commentsError;
  final TextEditingController _commentController =
      TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(recipeApiProvider);
      final recipe = await api.getRecipe(widget.recipeId);
      if (!mounted) return;

      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });

      if (widget.postId != null) {
        await _loadComments();
      }
    } catch (e) {
      // ignore: avoid_print
      print('getRecipe error: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not load recipe';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    if (widget.postId == null) return;

    setState(() {
      _commentsLoading = true;
      _commentsError = null;
    });

    try {
      final api = ref.read(commentApiProvider);
      final comments = await api.getComments(widget.postId!);
      if (!mounted) return;

      setState(() {
        _comments = comments;
        _commentsLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('getComments error: $e');
      if (mounted) {
        setState(() {
          _commentsError = 'Could not load comments';
          _commentsLoading = false;
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.postId == null) return;

    setState(() {
      _sendingComment = true;
    });

    try {
      final api = ref.read(commentApiProvider);
      final newComment =
          await api.addComment(widget.postId!, text);

      if (!mounted) return;

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
        _sendingComment = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('addComment error: $e');
      if (mounted) {
        setState(() {
          _sendingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not add comment'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?.name ?? 'Recipe'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : recipe == null
                  ? const Center(child: Text('Recipe not found'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _load();
                      },
                      child: SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (recipe.images.isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    recipe.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            Container(
                                      color: Colors
                                          .grey.shade300,
                                      child: const Center(
                                        child: Icon(
                                          Icons
                                              .image_not_supported,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              recipe.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            if (recipe.cookTimeMin != null)
                              Text(
                                'Cook time: ${recipe.cookTimeMin} min',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              recipe.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Nutrition (approx.)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _nutrientChip(
                                    'Calories',
                                    recipe.nutrients.calories,
                                    'kcal'),
                                _nutrientChip(
                                    'Protein',
                                    recipe.nutrients.protein,
                                    'g'),
                                _nutrientChip(
                                    'Carbs',
                                    recipe.nutrients.carbs,
                                    'g'),
                                _nutrientChip(
                                    'Fat',
                                    recipe.nutrients.fat,
                                    'g'),
                                _nutrientChip(
                                    'Fiber',
                                    recipe.nutrients.fiber,
                                    'g'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ingredients',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...recipe.ingredients.map(
                              (ing) => ListTile(
                                dense: true,
                                contentPadding:
                                    EdgeInsets.zero,
                                title: Text(ing.name),
                                trailing: Text(
                                    '${ing.quantity} ${ing.unit}'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Steps',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...recipe.steps.asMap().entries.map(
                              (entry) {
                                final idx = entry.key;
                                final step = entry.value;
                                return ListTile(
                                  dense: true,
                                  contentPadding:
                                      EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    child: Text(
                                      '${idx + 1}',
                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(step),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            if (widget.postId != null) ...[
                              Divider(
                                height: 32,
                                color:
                                    Colors.grey.shade300,
                              ),
                              Text(
                                'Comments',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (_commentsLoading)
                                const Padding(
                                  padding:
                                      EdgeInsets.all(8.0),
                                  child:
                                      CircularProgressIndicator(),
                                )
                              else if (_commentsError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .all(8.0),
                                  child: Text(
                                    _commentsError!,
                                    style: const TextStyle(
                                        color: Colors.red),
                                  ),
                                )
                              else if (_comments.isEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.all(8.0),
                                  child: Text(
                                      'No comments yet.'),
                                )
                              else
                                Column(
                                  children: _comments
                                      .map(
                                        (c) => ListTile(
                                          dense: true,
                                          contentPadding:
                                              EdgeInsets
                                                  .zero,
                                          title:
                                              Text(c.authorName),
                                          subtitle:
                                              Text(c.content),
                                          trailing: Text(
                                            _formatTime(
                                                c.createdAt),
                                            style: Theme.of(
                                                    context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          _commentController,
                                      decoration:
                                          const InputDecoration(
                                        hintText:
                                            'Add a comment...',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: _sendingComment
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send),
                                    onPressed: _sendingComment
                                            ? null
                                            : _sendComment,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _nutrientChip(
      String label, double value, String unit) {
    return Chip(
      label: Text('$label: ${value.toStringAsFixed(1)} $unit'),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

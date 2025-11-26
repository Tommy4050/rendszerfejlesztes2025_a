import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../infrastructure/recipe_api.dart';
import '../infrastructure/ingredient_search_api.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookTimeController = TextEditingController();

  // simple dynamic ingredient list (name, quantity, unit, + internal barcode)
  final List<_IngredientRow> _ingredients = [_IngredientRow()];

  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];

  File? _imageFile;
  bool _isSaving = false;
  String? _errorMessage;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cookTimeController.dispose();
    for (final s in _stepControllers) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(_IngredientRow());
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      if (_ingredients.length > 1) {
        _ingredients.removeAt(index);
      }
    });
  }

  void _addStepField() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    setState(() {
      if (_stepControllers.length > 1) {
        final c = _stepControllers.removeAt(index);
        c.dispose();
      }
    });
  }

  /// Opens a bottom sheet that searches OpenFoodFacts by name,
  /// lets the user pick a product, and stores its barcode in [row].
  Future<void> _openIngredientSearch(_IngredientRow row) async {
    final api = ref.read(ingredientSearchApiProvider);
    final queryController = TextEditingController(text: row.nameController.text);
    List<IngredientSearchResult> results = [];
    bool isLoading = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> doSearch() async {
              final q = queryController.text.trim();
              if (q.length < 2) return;
              setModalState(() {
                isLoading = true;
                error = null;
              });
              try {
                final res = await api.search(q);
                setModalState(() {
                  results = res;
                });
              } catch (e) {
                // ignore: avoid_print
                print('Ingredient search error: $e');
                setModalState(() {
                  error = 'Search failed';
                });
              } finally {
                setModalState(() {
                  isLoading = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: queryController,
                    decoration: InputDecoration(
                      labelText: 'Search ingredient',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: doSearch,
                      ),
                    ),
                    onSubmitted: (_) => doSearch(),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  else if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No results yet'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (ctx, index) {
                          final r = results[index];
                          return ListTile(
                            title: Text(r.name),
                            subtitle:
                                r.brand.isNotEmpty ? Text(r.brand) : null,
                            onTap: () {
                              // Fill row with selection
                              row.nameController.text = r.name;
                              row.barcode = r.barcode;
                              Navigator.of(ctx).pop();
                              setState(() {}); // update UI
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(recipeApiProvider);

      // 1) Upload image if present
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await api.uploadImage(_imageFile!);
      }

      // 2) Build ingredients payload
      final ingredientsPayload = <Map<String, dynamic>>[];
      for (final row in _ingredients) {
        if (row.nameController.text.trim().isEmpty ||
            row.quantityController.text.trim().isEmpty ||
            row.unitController.text.trim().isEmpty) {
          continue; // skip incomplete
        }

        final quantity = double.tryParse(row.quantityController.text.trim());
        if (quantity == null) continue;

        ingredientsPayload.add({
          'name': row.nameController.text.trim(),
          'quantity': quantity,
          'unit': row.unitController.text.trim(),
          if (row.barcode != null && row.barcode!.isNotEmpty)
            'barcode': row.barcode,
        });
      }

      // 3) Steps
      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // 4) Cook time
      final cookTimeMin = int.tryParse(
        _cookTimeController.text.trim().isEmpty
            ? '0'
            : _cookTimeController.text.trim(),
      );

      // 5) Create recipe
      await api.createRecipe(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        cookTimeMin: cookTimeMin,
        ingredients: ingredientsPayload,
        steps: steps,
        images: imageUrl != null ? [imageUrl] : [],
      );

      if (mounted) {
        Navigator.of(context).pop(true); // return success
      }
    } catch (e) {
      if (e is DioException) {
        // ignore: avoid_print
        print(
            'Create recipe Dio error: ${e.response?.statusCode} ${e.response?.data}');
      } else {
        // ignore: avoid_print
        print('Create recipe error: $e');
      }
      setState(() {
        _errorMessage = 'Could not create recipe';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Recipe name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cookTimeController,
                decoration: const InputDecoration(
                    labelText: 'Cook time (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Image picker
              Text(
                'Image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick from gallery'),
                  ),
                  const SizedBox(width: 12),
                  if (_imageFile != null)
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Ingredients
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'Search ingredient',
                            onPressed: () => _openIngredientSearch(row),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeIngredientRow(index),
                          ),
                        ],
                      ),
                      if (row.barcode != null && row.barcode!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Selected product barcode: ${row.barcode}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addIngredientRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add ingredient'),
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._stepControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Step ${index + 1}',
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeStepField(index),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addStepField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add step'),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRecipe,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  // Filled when user selects a product from search
  String? barcode;
}

import 'dart:async';
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
  ConsumerState<CreateRecipeScreen> createState() =>
      _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookTimeController = TextEditingController();

  final List<TextEditingController> _stepControllers = [
    TextEditingController(),
  ];

  final List<_IngredientRow> _ingredients = [_IngredientRow()];

  File? _imageFile;
  bool _isSaving = false;
  String? _errorMessage;

  final _picker = ImagePicker();

  Timer? _ingredientSearchDebounce;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cookTimeController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final row in _ingredients) {
      row.dispose();
    }
    _ingredientSearchDebounce?.cancel();
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
    if (_ingredients.length <= 1) return;
    setState(() {
      final row = _ingredients.removeAt(index);
      row.dispose();
    });
  }

  void _addStepField() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      final c = _stepControllers.removeAt(index);
      c.dispose();
    });
  }

  void _onIngredientNameChanged(int index, String value) {
    if (index >= _ingredients.length) return;
    final row = _ingredients[index];
    final query = value.trim();

    _ingredientSearchDebounce?.cancel();

    if (query.length < 2) {
      setState(() {
        row.suggestions = [];
        row.searchError = null;
        row.isSearching = false;
        row.barcode = null;
      });
      return;
    }

    _ingredientSearchDebounce =
        Timer(const Duration(milliseconds: 400), () {
      _performIngredientSearch(index, query);
    });
  }

  Future<void> _performIngredientSearch(int index, String query) async {
    if (!mounted || index >= _ingredients.length) return;
    final row = _ingredients[index];

    setState(() {
      row.isSearching = true;
      row.searchError = null;
    });

    try {
      final api = ref.read(ingredientSearchApiProvider);
      final results = await api.search(query);

      if (!mounted || index >= _ingredients.length) return;
      setState(() {
        row.suggestions = results;
        row.isSearching = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Ingredient search error: $e');
      if (!mounted || index >= _ingredients.length) return;
      setState(() {
        row.isSearching = false;
        row.searchError = 'Could not load suggestions';
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(recipeApiProvider);

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await api.uploadImage(_imageFile!);
      }

      final ingredientsPayload = <Map<String, dynamic>>[];
      for (final row in _ingredients) {
        final name = row.nameController.text.trim();
        final quantityText = row.quantityController.text.trim();
        final unit = row.unitController.text.trim();

        if (name.isEmpty || quantityText.isEmpty || unit.isEmpty) {
          continue;
        }

        final quantity = double.tryParse(quantityText);
        if (quantity == null) continue;

        ingredientsPayload.add({
          'name': name,
          'quantity': quantity,
          'unit': unit,
          if (row.barcode != null && row.barcode!.isNotEmpty)
            'barcode': row.barcode,
        });
      }

      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final cookTimeMin = int.tryParse(
        _cookTimeController.text.trim().isEmpty
            ? '0'
            : _cookTimeController.text.trim(),
      );

      await api.createRecipe(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        cookTimeMin: cookTimeMin,
        ingredients: ingredientsPayload,
        steps: steps,
        images: imageUrl != null ? [imageUrl] : [],
      );

      if (mounted) {
        Navigator.of(context).pop(true);
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not create recipe';
        });
      }
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
    final theme = Theme.of(context);

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
                decoration:
                    const InputDecoration(labelText: 'Recipe name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description'),
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

              Text(
                'Image',
                style: theme.textTheme.titleMedium,
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

              Text(
                'Ingredients',
                style: theme.textTheme.titleMedium,
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
                              onChanged: (value) =>
                                  _onIngredientNameChanged(index, value),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove ingredient',
                            onPressed: () =>
                                _removeIngredientRow(index),
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
                            child: DropdownButtonFormField<String>(
                              value: row.unitController.text.isEmpty
                                  ? null
                                  : row.unitController.text,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              items: const [
                                'g',
                                'kg',
                                'ml',
                                'l',
                                'tsp',
                                'tbsp',
                                'cup',
                                'piece',
                              ].map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  row.unitController.text = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      if (row.isSearching)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(),
                          ),
                        ),
                      if (row.searchError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            row.searchError!,
                            style:
                                const TextStyle(color: Colors.redAccent),
                          ),
                        ),

                      if (row.suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: row.suggestions.length,
                            itemBuilder: (ctx, i) {
                              final s = row.suggestions[i];
                              return ListTile(
                                dense: true,
                                title: Text(s.name),
                                subtitle: s.brand.isNotEmpty
                                    ? Text(s.brand)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    row.nameController.text = s.name;
                                    row.barcode = s.barcode;
                                    row.suggestions = [];
                                    row.isSearching = false;
                                    row.searchError = null;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                        ),

                      if (row.barcode != null &&
                          row.barcode!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Selected product barcode: ${row.barcode}',
                            style: theme.textTheme.bodySmall,
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

              Text(
                'Steps',
                style: theme.textTheme.titleMedium,
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
                        icon:
                            const Icon(Icons.remove_circle_outline),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
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
  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController quantityController =
      TextEditingController();
  final TextEditingController unitController =
      TextEditingController();

  String? barcode;

  List<IngredientSearchResult> suggestions = [];
  bool isSearching = false;
  String? searchError;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}

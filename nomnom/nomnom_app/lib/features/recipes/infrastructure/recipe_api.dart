import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

final recipeApiProvider = Provider<RecipeApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return RecipeApi(dio);
});

class RecipeApi {
  final Dio _dio;
  RecipeApi(this._dio);

  Future<String> uploadImage(File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/uploads/image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data as Map<String, dynamic>;
    return data['url'] as String; // Cloudinary URL
  }

  Future<void> createRecipe({
    required String name,
    required String description,
    int? cookTimeMin,
    required List<Map<String, dynamic>> ingredients,
    required List<String> steps,
    List<String>? images,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'cookTimeMin': cookTimeMin,
      'ingredients': ingredients,
      'steps': steps,
      'images': images ?? [],
    };

    await _dio.post('/recipes', data: payload);
  }

  Future<RecipeDetail> getRecipe(String id) async {
    final response = await _dio.get('/recipes/$id');
    final data = response.data as Map<String, dynamic>;

    final recipeJson = (data['recipe'] is Map)
        ? data['recipe'] as Map<String, dynamic>
        : data;

    return RecipeDetail.fromJson(recipeJson);
  }
}

class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

class RecipeNutrients {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  RecipeNutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory RecipeNutrients.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return RecipeNutrients(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
      );
    }

    double _d(dynamic v) =>
        v == null ? 0 : (v as num).toDouble();

    return RecipeNutrients(
      calories: _d(json['calories']),
      protein: _d(json['protein']),
      carbs: _d(json['carbs']),
      fat: _d(json['fat']),
      fiber: _d(json['fiber']),
    );
  }
}

class RecipeDetail {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final int? cookTimeMin;
  final List<RecipeIngredient> ingredients;
  final RecipeNutrients nutrients;
  final List<String> steps;

  RecipeDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.cookTimeMin,
    required this.ingredients,
    required this.nutrients,
    required this.steps,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];
    final totalNutrientsJson =
        json['totalNutrients'] as Map<String, dynamic>?;

    return RecipeDetail(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cookTimeMin: json['cookTimeMin'] as int?,
      ingredients: ingredientsJson
          .map((e) =>
              RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutrients: RecipeNutrients.fromJson(totalNutrientsJson),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class RecipeSummary {
  final String id;
  final String name;
  final String? imageUrl;
  final int? cookTimeMin;

  RecipeSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    this.cookTimeMin,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return RecipeSummary(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: images.isNotEmpty ? images.first : null,
      cookTimeMin: json['cookTimeMin'] as int?,
    );
  }
}

extension MyRecipesApi on RecipeApi {
  Future<List<RecipeSummary>> getMyRecipes() async {
    final response = await _dio.get('/recipes');
    final data = response.data;

    final list = data is List
        ? data
        : (data['recipes'] as List<dynamic>? ?? []);

    return list
        .map(
          (e) => RecipeSummary.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

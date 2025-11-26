import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

final ingredientSearchApiProvider =
    Provider<IngredientSearchApi>((ref) {
  final dio = ref.watch(authedDioProvider);
  return IngredientSearchApi(dio);
});

class IngredientSearchResult {
  final String name;
  final String brand;
  final String barcode;

  IngredientSearchResult({
    required this.name,
    required this.brand,
    required this.barcode,
  });

  factory IngredientSearchResult.fromJson(Map<String, dynamic> json) {
    return IngredientSearchResult(
      name: json['name'] as String? ?? 'Unknown',
      brand: json['brand'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
    );
  }
}

class IngredientSearchApi {
  final Dio _dio;
  IngredientSearchApi(this._dio);

  Future<List<IngredientSearchResult>> search(String query) async {
    if (query.trim().length < 2) return [];

    final response = await _dio.get(
      '/ingredients/search',
      queryParameters: {'q': query},
    );

    final data = response.data as Map<String, dynamic>;
    final list = data['products'] as List<dynamic>? ?? [];

    return list
        .map((e) =>
            IngredientSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

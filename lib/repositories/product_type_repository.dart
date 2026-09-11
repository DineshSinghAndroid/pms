import 'package:dio/dio.dart';

import '../models/product_type_model.dart';
import '../services/api_service.dart';

class ProductTypeRepository {
  final ApiService _apiService;

  ProductTypeRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Fetch all product types (optionally filtered by categoryId)
  Future<List<ProductTypeModel>> getProductTypes({int? categoryId}) async {
    try {
      final response = await _apiService.client.get(
        '/api/product-types',
        queryParameters: categoryId != null
            ? {'category_id': categoryId}
            : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map(
              (item) => ProductTypeModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load product types: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading product types',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create product type
  Future<ProductTypeModel> createProductType(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.client.post(
        '/api/product-types',
        data: payload,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return ProductTypeModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to create product type: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating product type',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update product type
  Future<ProductTypeModel> updateProductType(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.client.put(
        '/api/product-types/$id',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return ProductTypeModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to update product type: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating product type',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete product type
  Future<void> deleteProductType(int id) async {
    try {
      final response = await _apiService.client.delete(
        '/api/product-types/$id',
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete product type: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting product type',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

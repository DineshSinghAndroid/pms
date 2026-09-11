import 'package:dio/dio.dart';

import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Fetch all categories from backend
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiService.client.get('/api/categories');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading categories',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create category
  Future<CategoryModel> createCategory(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/api/categories',
        data: payload,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating category',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update category
  Future<CategoryModel> updateCategory(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.client.put(
        '/api/categories/$id',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update category: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating category',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(int id) async {
    try {
      final response = await _apiService.client.delete('/api/categories/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting category',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

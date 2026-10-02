import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/store_inventory_model.dart';
import '../services/api_service.dart';

class StoreInventoryResult {
  final StoreStatsModel stats;
  final List<CategoryModel> categories;
  final List<StoreProductModel> products;

  StoreInventoryResult({
    required this.stats,
    required this.categories,
    required this.products,
  });
}

class StoreRepository {
  final ApiService _apiService;

  StoreRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch store inventory with optional filters
  Future<StoreInventoryResult> fetchInventory({
    int? categoryId,
    String? stockStatus,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId;
      }
      if (stockStatus != null && stockStatus.isNotEmpty && stockStatus != 'all') {
        queryParams['stock_status'] = stockStatus;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _apiService.client.get(
        '/api/store/inventory',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final statsJson = body['stats'] is Map<String, dynamic>
            ? body['stats'] as Map<String, dynamic>
            : <String, dynamic>{};
        final stats = StoreStatsModel.fromJson(statsJson);

        final categoriesList = <CategoryModel>[];
        if (body['categories'] is List) {
          for (final item in body['categories'] as List) {
            if (item is Map<String, dynamic>) {
              categoriesList.add(CategoryModel.fromJson(item));
            } else if (item is Map) {
              categoriesList.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        final productsList = <StoreProductModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              productsList.add(StoreProductModel.fromJson(item));
            } else if (item is Map) {
              productsList.add(StoreProductModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        return StoreInventoryResult(
          stats: stats,
          categories: categoriesList,
          products: productsList,
        );
      }

      throw Exception('Failed to fetch store inventory: Invalid server response');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [StoreRepository.fetchInventory] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [StoreRepository.fetchInventory] Unexpected error: $e');
      throw Exception('Failed to load store inventory: $e');
    }
  }

  /// Fetch stock movement logs for a specific product
  Future<List<ProductStockLogModel>> fetchStockLogs(int productId) async {
    try {
      final response = await _apiService.client.get(
        '/api/store/inventory/$productId/logs',
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final logsList = <ProductStockLogModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              logsList.add(ProductStockLogModel.fromJson(item));
            } else if (item is Map) {
              logsList.add(ProductStockLogModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        return logsList;
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [StoreRepository.fetchStockLogs] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [StoreRepository.fetchStockLogs] Unexpected error: $e');
      throw Exception('Failed to fetch stock logs: $e');
    }
  }

  /// Adjust stock for a product
  Future<StoreProductModel> adjustStock(
    int productId, {
    required String adjustmentType,
    required int quantity,
    required String remarks,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/store/inventory/$productId/adjust',
        data: {
          'adjustment_type': adjustmentType,
          'quantity': quantity,
          'remarks': remarks,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (body['product'] is Map<String, dynamic>) {
          return StoreProductModel.fromJson(body['product'] as Map<String, dynamic>);
        } else if (body['product'] is Map) {
          return StoreProductModel.fromJson(Map<String, dynamic>.from(body['product'] as Map));
        }
      }
      throw Exception('Invalid response received from server.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [StoreRepository.adjustStock] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [StoreRepository.adjustStock] Unexpected error: $e');
      throw Exception('Failed to adjust stock: $e');
    }
  }
}

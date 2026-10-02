import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/sub_store_model.dart';
import '../services/api_service.dart';

class SubStoreInventoryResult {
  final SubStoreStatsModel stats;
  final List<SubStoreStockModel> items;

  SubStoreInventoryResult({
    required this.stats,
    required this.items,
  });
}

class SubStoreRepository {
  final ApiService _apiService;

  SubStoreRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch Sub-Store inventory
  Future<SubStoreInventoryResult> fetchInventory({
    String? stockStatus,
    String? search,
    int? subStoreId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (stockStatus != null && stockStatus.isNotEmpty && stockStatus != 'all') {
        queryParams['stock_status'] = stockStatus;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (subStoreId != null) {
        queryParams['sub_store_id'] = subStoreId;
      }

      final response = await _apiService.client.get(
        '/api/sub-store/inventory',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final statsJson = body['stats'] is Map<String, dynamic>
            ? body['stats'] as Map<String, dynamic>
            : <String, dynamic>{};
        final stats = SubStoreStatsModel.fromJson(statsJson);

        final itemsList = <SubStoreStockModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              itemsList.add(SubStoreStockModel.fromJson(item));
            } else if (item is Map) {
              itemsList.add(SubStoreStockModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        return SubStoreInventoryResult(
          stats: stats,
          items: itemsList,
        );
      }

      throw Exception('Failed to fetch sub-store inventory.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.fetchInventory] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.fetchInventory] Unexpected error: $e');
      throw Exception('Failed to load sub-store inventory: $e');
    }
  }

  /// Fetch sub-store transaction / audit logs for a product
  Future<List<SubStoreStockLogModel>> fetchLogs(int productTypeId) async {
    try {
      final response = await _apiService.client.get(
        '/api/sub-store/logs',
        queryParameters: {'product_type_id': productTypeId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final logsList = <SubStoreStockLogModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              logsList.add(SubStoreStockLogModel.fromJson(item));
            } else if (item is Map) {
              logsList.add(SubStoreStockLogModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        return logsList;
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.fetchLogs] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.fetchLogs] Unexpected error: $e');
      throw Exception('Failed to fetch logs: $e');
    }
  }

  /// Record stock consumption (Sub Store Incharge)
  Future<void> recordConsumption({
    required int productTypeId,
    required int quantity,
    required String purpose,
    String? department,
    String? remarks,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/sub-store/consume',
        data: {
          'product_type_id': productTypeId,
          'quantity': quantity,
          'purpose': purpose,
          if (department != null && department.isNotEmpty) 'department': department,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception('Failed to record consumption.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.recordConsumption] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.recordConsumption] Unexpected error: $e');
      throw Exception('Failed to record consumption: $e');
    }
  }

  /// Fetch list of Sub Store Incharges (for Main Store Incharge to select recipient)
  Future<List<SubStoreInchargeModel>> fetchIncharges() async {
    try {
      final response = await _apiService.client.get('/api/sub-store/incharges');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final incharges = <SubStoreInchargeModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              incharges.add(SubStoreInchargeModel.fromJson(item));
            } else if (item is Map) {
              incharges.add(SubStoreInchargeModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        return incharges;
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.fetchIncharges] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.fetchIncharges] Unexpected error: $e');
      throw Exception('Failed to load sub-store incharges: $e');
    }
  }

  /// Transfer stock from Main Store to Sub Store
  Future<void> transferStock({
    required int toUserId,
    required int productTypeId,
    required int quantity,
    String? remarks,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/store/transfers',
        data: {
          'to_user_id': toUserId,
          'items': [
            {
              'product_type_id': productTypeId,
              'quantity': quantity,
            }
          ],
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception('Failed to transfer stock.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.transferStock] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.transferStock] Unexpected error: $e');
      throw Exception('Failed to transfer stock: $e');
    }
  }

  /// Fetch all physical Sub-Stores
  Future<List<SubStoreEntityModel>> fetchSubStores() async {
    try {
      final response = await _apiService.client.get('/api/sub-stores');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final stores = <SubStoreEntityModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              stores.add(SubStoreEntityModel.fromJson(item));
            } else if (item is Map) {
              stores.add(SubStoreEntityModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        return stores;
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.fetchSubStores] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.fetchSubStores] Unexpected error: $e');
      throw Exception('Failed to load sub-stores: $e');
    }
  }

  /// Create a new Sub-Store
  Future<SubStoreEntityModel> createSubStore(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.client.post(
        '/api/sub-stores',
        data: data,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final storeJson = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(body['data'] as Map);

        return SubStoreEntityModel.fromJson(storeJson);
      }
      throw Exception('Failed to create sub-store.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.createSubStore] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.createSubStore] Unexpected error: $e');
      throw Exception('Failed to create sub-store: $e');
    }
  }

  /// Update an existing Sub-Store
  Future<SubStoreEntityModel> updateSubStore(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.client.put(
        '/api/sub-stores/$id',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final storeJson = body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(body['data'] as Map);

        return SubStoreEntityModel.fromJson(storeJson);
      }
      throw Exception('Failed to update sub-store.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.updateSubStore] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.updateSubStore] Unexpected error: $e');
      throw Exception('Failed to update sub-store: $e');
    }
  }

  /// Delete a Sub-Store
  Future<void> deleteSubStore(int id) async {
    try {
      final response = await _apiService.client.delete('/api/sub-stores/$id');
      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Failed to delete sub-store.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.deleteSubStore] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.deleteSubStore] Unexpected error: $e');
      throw Exception('Failed to delete sub-store: $e');
    }
  }

  /// Fetch all stock consumption logs across sub-stores
  Future<List<SubStoreConsumptionModel>> fetchConsumptions({
    int? subStoreId,
    int? userId,
    int? productTypeId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (subStoreId != null) queryParams['sub_store_id'] = subStoreId;
      if (userId != null) queryParams['user_id'] = userId;
      if (productTypeId != null) queryParams['product_type_id'] = productTypeId;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final response = await _apiService.client.get(
        '/api/sub-store/consumptions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final items = <SubStoreConsumptionModel>[];
        if (body['data'] is List) {
          for (final item in body['data'] as List) {
            if (item is Map<String, dynamic>) {
              items.add(SubStoreConsumptionModel.fromJson(item));
            } else if (item is Map) {
              items.add(SubStoreConsumptionModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        return items;
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('🚨 [SubStoreRepository.fetchConsumptions] Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('🚨 [SubStoreRepository.fetchConsumptions] Unexpected error: $e');
      throw Exception('Failed to fetch consumptions: $e');
    }
  }
}

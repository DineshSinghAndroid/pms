import 'package:dio/dio.dart';

import '../models/digital_studio_asset_model.dart';
import '../models/digital_studio_crew_request_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class DigitalStudioRepository {
  final ApiService _apiService;

  DigitalStudioRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ==========================================
  // ASSET MANAGEMENT APIS
  // ==========================================

  /// Fetch all assets
  Future<List<DigitalStudioAssetModel>> getAssets({
    String? category,
    String? status,
    String? search,
    String? phone,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      final response = await _apiService.client.get(
        '/api/digital-studio/assets',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => DigitalStudioAssetModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return [];
      }
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error loading assets',
      );
    } catch (e) {
      return [];
    }
  }

  /// Create a new asset
  Future<DigitalStudioAssetModel> createAsset(Map<String, dynamic> payload, {String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/assets',
        data: payload,
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to create asset: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error creating asset',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get single asset with logs
  Future<DigitalStudioAssetModel> getAsset(int id) async {
    try {
      final response = await _apiService.client.get('/api/digital-studio/assets/$id');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to load asset details');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error loading asset details',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Assign asset
  Future<DigitalStudioAssetModel> assignAsset(int assetId, {required int userId, int? requestId, String? remarks, String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/assets/$assetId/assign',
        data: {
          'user_id': userId,
          'request_id': ?requestId,
          'remarks': ?remarks,
        },
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to assign asset');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error assigning asset',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Return / Re-submit asset
  Future<DigitalStudioAssetModel> returnAsset(int assetId, {String? remarks, String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/assets/$assetId/return',
        data: {'remarks': ?remarks},
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to return asset');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error returning asset',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Reassign asset
  Future<DigitalStudioAssetModel> reassignAsset(int assetId, {required int userId, int? requestId, String? remarks, String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/assets/$assetId/reassign',
        data: {
          'user_id': userId,
          'request_id': ?requestId,
          'remarks': ?remarks,
        },
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to reassign asset');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error reassigning asset',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update asset status (maintenance, damaged, available)
  Future<DigitalStudioAssetModel> updateAssetStatus(int assetId, {required String status, String? remarks, String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/assets/$assetId/status',
        data: {'status': status, 'remarks': ?remarks},
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioAssetModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update status');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error updating status',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ==========================================
  // CREW REQUESTS & ALLOTMENT APIS
  // ==========================================

  /// Fetch all crew requests
  Future<List<DigitalStudioCrewRequestModel>> getCrewRequests({
    int? wingId,
    String? status,
    String? search,
    String? phone,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (wingId != null) queryParams['wing_id'] = wingId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      final response = await _apiService.client.get(
        '/api/digital-studio/crew-requests',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => DigitalStudioCrewRequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return [];
      }
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error loading crew requests',
      );
    } catch (e) {
      return [];
    }
  }

  /// Create a new crew request
  Future<DigitalStudioCrewRequestModel> createCrewRequest(Map<String, dynamic> payload, {String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/crew-requests',
        data: payload,
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioCrewRequestModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to create crew request');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error creating crew request',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Allot crew members and assets to a request
  Future<DigitalStudioCrewRequestModel> allotCrewRequest(
    int requestId, {
    required List<int> employeeIds,
    List<int> assetIds = const [],
    String? remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/digital-studio/crew-requests/$requestId/allot',
        data: {
          'employee_ids': employeeIds,
          'asset_ids': assetIds,
          'remarks': ?remarks,
        },
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioCrewRequestModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to allot crew and assets');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error allotting crew and assets',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update crew request status (e.g. in_progress, completed, cancelled)
  Future<DigitalStudioCrewRequestModel> updateCrewRequestStatus(
    int requestId, {
    required String status,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.patch(
        '/api/digital-studio/crew-requests/$requestId/status',
        data: {'status': status},
        queryParameters: phone != null ? {'phone': phone} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return DigitalStudioCrewRequestModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update request status');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error updating request status',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ==========================================
  // EMPLOYEE SCHEDULE CALENDAR APIS
  // ==========================================

  /// Fetch schedule calendar (with allotted employees & gear)
  Future<List<DigitalStudioCrewRequestModel>> getScheduleCalendar({
    String? startDate,
    String? endDate,
    int? employeeId,
    String? phone,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (employeeId != null) queryParams['employee_id'] = employeeId;
      if (phone != null) queryParams['phone'] = phone;

      final response = await _apiService.client.get(
        '/api/digital-studio/schedule-calendar',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => DigitalStudioCrewRequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return [];
      }
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error loading schedule calendar',
      );
    } catch (e) {
      return [];
    }
  }

  /// List eligible crew members (Designers / Studio team)
  Future<List<UserModel>> getCrewMembers() async {
    try {
      final response = await _apiService.client.get('/api/digital-studio/crew-members');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// List available assets
  Future<List<DigitalStudioAssetModel>> getAvailableAssets() async {
    try {
      final response = await _apiService.client.get('/api/digital-studio/available-assets');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => DigitalStudioAssetModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

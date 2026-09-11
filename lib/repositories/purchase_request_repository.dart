import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/purchase_request_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class PurchaseRequestRepository {
  final ApiService _apiService;

  PurchaseRequestRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<PurchaseRequestModel>> getPurchaseRequests({
    int? designerId,
    String? phone,
    String? status,
    int? wingId,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (designerId != null) params['designer_id'] = designerId;
      if (phone != null && phone.isNotEmpty) params['phone'] = phone;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (wingId != null) params['wing_id'] = wingId;

      final response = await _apiService.client.get(
        '/api/purchase-requests',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map(
              (item) =>
                  PurchaseRequestModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading purchase requests',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> getPurchaseRequestDetails(int prId) async {
    try {
      final response = await _apiService.client.get(
        '/api/purchase-requests/$prId',
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to load PR details: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading PR details',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<UserModel>> getDesigners() async {
    try {
      final response = await _apiService.client.get('/api/designers');
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
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading designers',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> createPurchaseRequest(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to create purchase request: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating purchase request',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> assignDesigner(int prId, int designerId) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/assign-designer',
        data: {'designer_id': designerId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to assign designer: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error assigning designer',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> startWork(int prId, {String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/start-work',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to start work: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error starting work',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> submitWork(
    int prId, {
    String? remarks,
    String? artworkPath,
    String? artworkName,
    List<int>? fileBytes,
    String? phone,
  }) async {
    try {
      dynamic postData;

      if (fileBytes != null && fileBytes.isNotEmpty) {
        final fileName = (artworkName != null && artworkName.isNotEmpty)
            ? artworkName
            : 'artwork_${DateTime.now().millisecondsSinceEpoch}.png';
        final entries = <String, dynamic>{
          'artwork': MultipartFile.fromBytes(fileBytes, filename: fileName),
          'artwork_name': fileName,
          'artwork_base64': base64Encode(fileBytes),
        };
        if (remarks != null) entries['remarks'] = remarks;
        if (phone != null) entries['phone'] = phone;
        postData = FormData.fromMap(entries);
      } else {
        postData = {
          'remarks': remarks,
          'artwork_path': artworkPath,
          'artwork_name': artworkName,
          'phone': phone,
        };
      }

      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/submit-work',
        data: postData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to submit work: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error submitting work',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> approvePR(
    int prId, {
    String? remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/approve',
        data: {'remarks': remarks, 'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to approve PR: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error approving PR',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> rejectRevisionPR(
    int prId, {
    required String remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/reject-revision',
        data: {'remarks': remarks, 'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to reject PR: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error rejecting PR',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> postIt(
    int prId, {
    String? remarks,
    String? phone,
  }) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/post-it',
        data: {'remarks': remarks, 'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to submit post request: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error submitting post request',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> cancelPost(int prId, {String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/cancel-post',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to cancel post request: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error cancelling post request',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PurchaseRequestModel> cancelPrint(int prId, {String? phone}) async {
    try {
      final response = await _apiService.client.post(
        '/api/purchase-requests/$prId/cancel-print',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return PurchaseRequestModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to cancel print order: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error cancelling print order',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> deletePurchaseRequest(int prId) async {
    try {
      final response = await _apiService.client.delete(
        '/api/purchase-requests/$prId',
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete purchase request: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting purchase request',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

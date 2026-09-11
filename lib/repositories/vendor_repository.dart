import 'package:dio/dio.dart';

import '../models/vendor_model.dart';
import '../services/api_service.dart';

class VendorRepository {
  final ApiService _apiService;

  VendorRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Fetch all vendors from PMS Admin backend
  Future<List<VendorModel>> getVendors() async {
    try {
      final response = await _apiService.client.get('/api/vendors');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => VendorModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load vendors: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error connecting to PMS Admin',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new printing vendor
  Future<VendorModel> createVendor(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/api/vendors',
        data: payload,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return VendorModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create vendor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating vendor',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing vendor
  Future<VendorModel> updateVendor(
    int vendorId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.client.put(
        '/api/vendors/$vendorId',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return VendorModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update vendor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating vendor',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete a vendor
  Future<void> deleteVendor(int vendorId) async {
    try {
      final response = await _apiService.client.delete(
        '/api/vendors/$vendorId',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete vendor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting vendor',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Toggle vendor login access
  Future<VendorModel> toggleVendorLogin(int vendorId) async {
    try {
      final response = await _apiService.client.post(
        '/api/vendors/$vendorId/toggle-login',
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return VendorModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to toggle login access: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error toggling login access',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

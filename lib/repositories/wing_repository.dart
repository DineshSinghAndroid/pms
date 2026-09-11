import 'package:dio/dio.dart';

import '../models/wing_model.dart';
import '../services/api_service.dart';

class WingRepository {
  final ApiService _apiService;

  WingRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Fetch all institute wings
  Future<List<WingModel>> getWings() async {
    try {
      final response = await _apiService.client.get('/api/wings');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => WingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load wings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error loading wings',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create wing
  Future<WingModel> createWing(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/api/wings',
        data: payload,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return WingModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create wing: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating wing',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update wing
  Future<WingModel> updateWing(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.put(
        '/api/wings/$id',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return WingModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update wing: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating wing',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete wing
  Future<void> deleteWing(int id) async {
    try {
      final response = await _apiService.client.delete('/api/wings/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete wing: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting wing',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

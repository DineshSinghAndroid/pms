import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Fetch all users from PMS Admin backend
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _apiService.client.get('/api/users');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
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

  /// Create a new user
  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.post(
        '/api/users',
        data: payload,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error creating user',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing user
  Future<UserModel> updateUser(int userId, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.client.put(
        '/api/users/$userId',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error updating user',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete a user
  Future<void> deleteUser(int userId) async {
    try {
      final response = await _apiService.client.delete('/api/users/$userId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error deleting user',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Toggle user active status
  Future<UserModel> toggleUserActive(int userId) async {
    try {
      final response = await _apiService.client.post(
        '/api/users/$userId/toggle-active',
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.message ??
            'Network error toggling status',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get user profile by phone number
  Future<UserModel?> getProfile(String phone) async {
    try {
      final response = await _apiService.client.get(
        '/api/profile',
        queryParameters: {'phone': phone},
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (body['user'] != null && body['user'] is Map<String, dynamic>) {
          return UserModel.fromJson(body['user'] as Map<String, dynamic>);
        } else if (body['role'] != null) {
          return UserModel(
            id: body['id'] as int? ?? 0,
            name: body['name'] as String? ?? 'User',
            phone: body['phone'] as String? ?? phone,
            role: body['role'] as String? ?? 'manager',
            isActive: body['is_login_allowed'] as bool? ?? true,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

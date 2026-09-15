import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class InactiveUserException implements Exception {
  final String message;
  const InactiveUserException([this.message = 'Your user account is marked inactive. Contact Super Admin.']);

  @override
  String toString() => message;
}

class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Map<String, dynamic>? _buildAuthParams(String? phone) {
    final effectivePhone = phone ?? ApiService.activeUserPhone;
    if (effectivePhone != null && effectivePhone.trim().isNotEmpty) {
      final clean = effectivePhone.replaceAll(RegExp(r'\D'), '');
      final standard = clean.length > 10 ? clean.substring(clean.length - 10) : clean;
      return {'phone': standard};
    }
    return null;
  }

  /// Fetch all users from PMS Admin backend
  Future<List<UserModel>> getUsers({String? phone}) async {
    final qParams = _buildAuthParams(phone);
    debugPrint('👥 [UserRepository] GET /api/users (params: $qParams)...');
    try {
      final response = await _apiService.client.get(
        '/api/users',
        queryParameters: qParams,
      );
      debugPrint('👥 [UserRepository] GET /api/users status: ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        final users = dataList
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('👥 [UserRepository] Loaded ${users.length} users successfully.');
        return users;
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error connecting to PMS Admin';
      debugPrint('❌ [UserRepository] DioException on getUsers: $errorMsg (Status: ${e.response?.statusCode})');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [UserRepository] Unexpected error on getUsers: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new user
  Future<UserModel> createUser(Map<String, dynamic> payload, {String? phone}) async {
    final qParams = _buildAuthParams(phone);
    debugPrint('👥 [UserRepository] POST /api/users with payload: $payload, params: $qParams');
    try {
      final response = await _apiService.client.post(
        '/api/users',
        data: payload,
        queryParameters: qParams,
      );
      debugPrint('👥 [UserRepository] POST /api/users status: ${response.statusCode}');
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final user = UserModel.fromJson(body['data'] as Map<String, dynamic>);
        debugPrint('✅ [UserRepository] Created user: ${user.name} (ID: ${user.id})');
        return user;
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error creating user';
      debugPrint('❌ [UserRepository] DioException on createUser: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [UserRepository] Unexpected error on createUser: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing user
  Future<UserModel> updateUser(int userId, Map<String, dynamic> payload, {String? phone}) async {
    final qParams = _buildAuthParams(phone);
    debugPrint('👥 [UserRepository] PUT /api/users/$userId with payload: $payload, params: $qParams');
    try {
      final response = await _apiService.client.put(
        '/api/users/$userId',
        data: payload,
        queryParameters: qParams,
      );
      debugPrint('👥 [UserRepository] PUT /api/users/$userId status: ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final user = UserModel.fromJson(body['data'] as Map<String, dynamic>);
        debugPrint('✅ [UserRepository] Updated user: ${user.name} (ID: ${user.id})');
        return user;
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error updating user';
      debugPrint('❌ [UserRepository] DioException on updateUser: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [UserRepository] Unexpected error on updateUser: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete a user
  Future<void> deleteUser(int userId, {String? phone}) async {
    final qParams = _buildAuthParams(phone);
    debugPrint('👥 [UserRepository] DELETE /api/users/$userId (params: $qParams)');
    try {
      final response = await _apiService.client.delete(
        '/api/users/$userId',
        queryParameters: qParams,
      );
      debugPrint('👥 [UserRepository] DELETE /api/users/$userId status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
      debugPrint('✅ [UserRepository] Deleted user: $userId');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error deleting user';
      debugPrint('❌ [UserRepository] DioException on deleteUser: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [UserRepository] Unexpected error on deleteUser: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Toggle user active status
  Future<UserModel> toggleUserActive(int userId, {String? phone}) async {
    final qParams = _buildAuthParams(phone);
    debugPrint('👥 [UserRepository] POST /api/users/$userId/toggle-active (params: $qParams)');
    try {
      final response = await _apiService.client.post(
        '/api/users/$userId/toggle-active',
        queryParameters: qParams,
      );
      debugPrint('👥 [UserRepository] POST toggle status: ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final user = UserModel.fromJson(body['data'] as Map<String, dynamic>);
        debugPrint('✅ [UserRepository] Toggled status for user ${user.name}: active=${user.isActive}');
        return user;
      } else {
        throw Exception('Failed to toggle status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error toggling status';
      debugPrint('❌ [UserRepository] DioException on toggleUserActive: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ [UserRepository] Unexpected error on toggleUserActive: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get user profile by phone number
  Future<UserModel?> getProfile(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final standard = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    debugPrint('👤 [UserRepository] getProfile for: $standard');

    try {
      final response = await _apiService.client.get(
        '/api/profile',
        queryParameters: {'phone': standard},
      );

      if (response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (body['is_login_allowed'] == false || body['success'] == false) {
          final msg = body['message'] as String? ?? 'Your user account is marked inactive. Contact Super Admin.';
          throw InactiveUserException(msg);
        }

        if (body['user'] != null && body['user'] is Map<String, dynamic>) {
          final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);
          if (!user.isActive && !user.isSuperAdmin) {
            throw const InactiveUserException();
          }
          return user;
        } else if (body['role'] != null) {
          final roleStr = (body['role'] as String? ?? '').toLowerCase().trim();
          final isSuper = roleStr == 'superadmin' || roleStr == 'super admin' || roleStr == 'super_admin';
          final isActive = body['is_login_allowed'] == null ? true : (body['is_login_allowed'] == true || body['is_login_allowed'] == 1 || body['is_login_allowed'] == '1');
          if (!isActive && !isSuper) {
            throw const InactiveUserException();
          }
          return UserModel(
            id: body['id'] as int? ?? 0,
            name: body['name'] as String? ?? 'User',
            phone: body['phone'] as String? ?? standard,
            role: body['role'] as String? ?? 'manager',
            isActive: isActive,
          );
        }
      }
      return null;
    } on InactiveUserException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        String msg = 'Your user account is marked inactive. Contact Super Admin.';
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          msg = (data['message'] ?? data['error']).toString();
        }
        throw InactiveUserException(msg);
      }
      debugPrint('❌ [UserRepository] DioException on getProfile: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error on getProfile: $e');
      return null;
    }
  }
}

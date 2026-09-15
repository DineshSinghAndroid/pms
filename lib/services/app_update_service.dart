import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_info.dart';
import '../widgets/app_update_dialog.dart';
import 'api_service.dart';

class AppUpdateService {
  final ApiService _apiService;

  AppUpdateService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Retrieve active build number from device package info
  static Future<int> getCurrentBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final parsed = int.tryParse(info.buildNumber);
      if (parsed != null && parsed > 0) return parsed;
    } catch (e) {
      debugPrint('⚠️ [AppUpdateService] Error fetching PackageInfo buildNumber: $e');
    }
    // Fallback if PackageInfo unavailable in test or mock environment
    return 4;
  }

  /// Retrieve current version string (e.g. 2.0.0)
  static Future<String> getCurrentVersionString() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '2.0.0';
    }
  }

  /// Fetch update configuration from backend API (bypassing any cached response)
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await _apiService.client.get(
        '/api/app-update',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (body['data'] != null) {
          final dataMap = body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : Map<String, dynamic>.from(body['data'] as Map);
          return AppUpdateInfo.fromJson(dataMap);
        }
      }
    } catch (e) {
      debugPrint('🚨 [AppUpdateService] Failed to fetch app update config: $e');
    }
    return null;
  }

  /// Update app configuration (Super Admin / Admin / Manager)
  Future<AppUpdateInfo?> saveUpdateInfo(
    AppUpdateInfo info, {
    String? userPhone,
  }) async {
    try {
      final payload = info.toJson();

      // Resolve phone from parameter, ApiService.activeUserPhone, or FirebaseAuth
      String? phone = userPhone;
      if (phone == null || phone.isEmpty) {
        phone = ApiService.activeUserPhone;
      }
      if (phone == null || phone.isEmpty) {
        phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      }

      if (phone != null && phone.isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'\D'), '');
        final standard = clean.length > 10 ? clean.substring(clean.length - 10) : clean;
        payload['phone'] = standard;
        payload['user_phone'] = standard;
      }

      final response = await _apiService.client.post(
        '/api/admin/app-update',
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (body['data'] != null) {
          final dataMap = body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : Map<String, dynamic>.from(body['data'] as Map);
          return AppUpdateInfo.fromJson(dataMap);
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Update failed';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
    return null;
  }

  /// Flag to prevent duplicate update dialogs from stacking
  static bool isUpdateDialogOpen = false;

  /// Automatic or manual update checker.
  /// Shows [AppUpdateDialog] if current build is lower than server latest build.
  Future<bool> checkForUpdate(
    BuildContext context, {
    bool showToastIfUpToDate = false,
  }) async {
    final int currentBuild = await getCurrentBuildNumber();
    final String versionName = await getCurrentVersionString();
    final updateInfo = await fetchUpdateInfo();

    final bool isAvailable =
        updateInfo != null && updateInfo.isUpdateAvailable(currentBuild);

    debugPrint(
      '🔍 [AppUpdateService] Version check -> Device: #$currentBuild (v$versionName), '
      'Server: #${updateInfo?.latestBuildNumber}, '
      'Force: ${updateInfo?.isForceUpdate}, '
      'Update Available: $isAvailable',
    );

    if (!context.mounted) return false;

    if (isAvailable) {
      if (isUpdateDialogOpen) {
        debugPrint('⚠️ [AppUpdateService] Update dialog already open, skipping duplicate.');
        return true;
      }

      isUpdateDialogOpen = true;
      try {
        debugPrint('🚀 [AppUpdateService] Displaying update dialog to user...');
        await showDialog(
          context: context,
          barrierDismissible: !updateInfo.isForceUpdate,
          builder: (ctx) => AppUpdateDialog(
            updateInfo: updateInfo,
            currentBuildNumber: currentBuild,
            currentVersionName: versionName,
          ),
        );
      } finally {
        isUpdateDialogOpen = false;
      }
      return true;
    } else if (showToastIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'You are on the latest version (Build #$currentBuild)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return false;
  }
}

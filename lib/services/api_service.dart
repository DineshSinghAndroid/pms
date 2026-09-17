import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../widgets/loading_system.dart';

class ApiService {
  late final Dio _dio;

  /// Global active user phone tracking for API requests
  static String? activeUserPhone;

  /// Set the active user phone globally across all repositories
  static void setUserPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    activeUserPhone = clean.length > 10 ? clean.substring(clean.length - 10) : clean;
    debugPrint('📱 [ApiService] Global activeUserPhone set to: $activeUserPhone');
  }

  // Base URL: Local LAN for device/dev, or live production
  static const String liveServerUrl = 'https://pms.bytscop.com/';
  static const String localServerUrl = 'https://pms.bytscop.com/';

  /// Prefer local admin when debugging; use live in release builds.
  static String get baseUrl {
    if (kDebugMode) {
      return localServerUrl;
    }

    return liveServerUrl;
  }

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Auth & Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Trigger screen-overlapped Prince Group loading animation
          String msg = 'Connecting to server';
          final method = options.method.toUpperCase();
          if (method == 'GET') {
            msg = 'Fetching data';
          } else if (method == 'POST') {
            msg = 'Saving data';
          } else if (method == 'PUT' || method == 'PATCH') {
            msg = 'Updating record';
          } else if (method == 'DELETE') {
            msg = 'Deleting record';
          }
          LoadingService().startLoading(message: msg);

          // 1. Resolve phone from ApiService.activeUserPhone or FirebaseAuth
          String? phone = activeUserPhone;
          if (phone == null || phone.isEmpty) {
            try {
              final fbPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
              if (fbPhone != null && fbPhone.isNotEmpty) {
                final clean = fbPhone.replaceAll(RegExp(r'\D'), '');
                phone = clean.length > 10 ? clean.substring(clean.length - 10) : clean;
              }
            } catch (e) {
              debugPrint('⚠️ [ApiService] Error checking FirebaseAuth currentUser: $e');
            }
          }

          if (phone != null && phone.isNotEmpty) {
            options.headers['X-User-Phone'] = phone;
            debugPrint('🔐 [ApiService] Injected Header -> X-User-Phone: $phone on [${options.method}] ${options.uri}');
          } else {
            debugPrint('⚠️ [ApiService] No user phone attached for [${options.method}] ${options.uri}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          LoadingService().stopLoading();
          debugPrint('🌐 [ApiService Response] ${response.statusCode} from [${response.requestOptions.method}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          LoadingService().stopLoading();
          debugPrint('🚨 [ApiService Error] Status: ${error.response?.statusCode} on [${error.requestOptions.method}] ${error.requestOptions.path}');
          debugPrint('🚨 [ApiService Error Data]: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('🌐 [Dio] $obj'),
        ),
      );
    }
  }

  Dio get client => _dio;

  /// Sync current user GPS location to backend server
  Future<bool> updateUserLocation(double latitude, double longitude, {String? address, String? source}) async {
    try {
      final res = await _dio.post('/api/users/update-location', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        'source': source ?? 'mobile_app',
      });
      return res.data != null && res.data['success'] == true;
    } catch (e) {
      debugPrint('⚠️ [ApiService] Error syncing location: $e');
      return false;
    }
  }
}

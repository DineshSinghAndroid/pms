import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  // Base URL: Live Production Server
  static const String liveServerUrl = 'https://pms.bytscop.com';

  static String get baseUrl {
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
}

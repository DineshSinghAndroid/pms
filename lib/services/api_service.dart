import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  // Base URL: Supports Local Network IP (192.168.1.9 for physical iPhone & Simulator), or dynamic host for Web
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != '0.0.0.0') {
        return 'http://$host:8000';
      }
      return 'http://192.168.1.9:8000';
    }
    // Mac IP on local network for physical iPhone
    return 'http://192.168.1.9:8000';
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

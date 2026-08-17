import 'package:dio/dio.dart';
import '../models/announcement_model.dart';
import '../services/api_service.dart';

class AnnouncementRepository {
  final ApiService _apiService;

  AnnouncementRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch the latest broadcast announcement from PMS Admin backend
  Future<AnnouncementModel> getLatestAnnouncement() async {
    try {
      final response = await _apiService.client.get('/api/announcement');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return AnnouncementModel.fromJson(data);
      } else {
        throw Exception('Failed to load announcement: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Network error connecting to PMS Admin',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

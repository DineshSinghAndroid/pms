import 'package:dio/dio.dart';
import '../models/hoarding_city_model.dart';
import '../models/hoarding_vendor_model.dart';
import '../models/hoarding_site_model.dart';
import '../models/hoarding_site_log_model.dart';
import '../services/api_service.dart';

class HoardingRepository {
  final ApiService _apiService;

  HoardingRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ── Cities ────────────────────────────────────────────────────────
  Future<List<HoardingCityModel>> getCities() async {
    try {
      final res = await _apiService.client.get('/api/hoarding/cities');
      final data = (res.data['data'] as List<dynamic>? ?? []);
      return data.map((e) => HoardingCityModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to load cities');
    }
  }

  Future<HoardingCityModel> createCity(Map<String, dynamic> data) async {
    try {
      final res = await _apiService.client.post('/api/hoarding/cities', data: data);
      return HoardingCityModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to create city');
    }
  }

  Future<HoardingCityModel> updateCity(int id, Map<String, dynamic> data) async {
    try {
      final res = await _apiService.client.put('/api/hoarding/cities/$id', data: data);
      return HoardingCityModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to update city');
    }
  }

  Future<void> deleteCity(int id) async {
    try {
      await _apiService.client.delete('/api/hoarding/cities/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to delete city');
    }
  }

  // ── Vendors ───────────────────────────────────────────────────────
  Future<List<HoardingVendorModel>> getVendors() async {
    try {
      final res = await _apiService.client.get('/api/hoarding/vendors');
      final data = (res.data['data'] as List<dynamic>? ?? []);
      return data.map((e) => HoardingVendorModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to load vendors');
    }
  }

  Future<HoardingVendorModel> createVendor(Map<String, dynamic> data) async {
    try {
      final res = await _apiService.client.post('/api/hoarding/vendors', data: data);
      return HoardingVendorModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to create vendor');
    }
  }

  Future<HoardingVendorModel> updateVendor(int id, Map<String, dynamic> data) async {
    try {
      final res = await _apiService.client.put('/api/hoarding/vendors/$id', data: data);
      return HoardingVendorModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to update vendor');
    }
  }

  Future<void> deleteVendor(int id) async {
    try {
      await _apiService.client.delete('/api/hoarding/vendors/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to delete vendor');
    }
  }

  // ── Sites ─────────────────────────────────────────────────────────
  Future<List<HoardingSiteModel>> getSites({
    int? cityId,
    int? vendorId,
    String? type,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (cityId != null && cityId > 0) params['city_id'] = cityId;
      if (vendorId != null && vendorId > 0) params['vendor_id'] = vendorId;
      if (type != null && type.isNotEmpty && type != 'All') params['type'] = type;
      if (status != null && status.isNotEmpty && status != 'All') params['status'] = status;

      final res = await _apiService.client.get('/api/hoarding/sites', queryParameters: params);
      final data = (res.data['data'] as List<dynamic>? ?? []);
      return data.map((e) => HoardingSiteModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to load sites');
    }
  }

  Future<HoardingSiteModel> getSite(int id) async {
    try {
      final res = await _apiService.client.get('/api/hoarding/sites/$id');
      return HoardingSiteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to load site details');
    }
  }

  Future<HoardingSiteModel> createSite(Map<String, dynamic> data, {String? photoFilePath}) async {
    try {
      final res = await _apiService.client.post('/api/hoarding/sites', data: data);
      final site = HoardingSiteModel.fromJson(res.data['data'] as Map<String, dynamic>);

      if (photoFilePath != null && photoFilePath.isNotEmpty) {
        return await uploadSitePhoto(site.id, photoFilePath);
      }
      return site;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to create site');
    }
  }

  Future<HoardingSiteModel> updateSite(int id, Map<String, dynamic> data, {String? photoFilePath}) async {
    try {
      final res = await _apiService.client.put('/api/hoarding/sites/$id', data: data);
      final site = HoardingSiteModel.fromJson(res.data['data'] as Map<String, dynamic>);

      if (photoFilePath != null && photoFilePath.isNotEmpty) {
        return await uploadSitePhoto(site.id, photoFilePath);
      }
      return site;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to update site');
    }
  }

  Future<void> deleteSite(int id) async {
    try {
      await _apiService.client.delete('/api/hoarding/sites/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to delete site');
    }
  }

  Future<HoardingSiteModel> uploadSitePhoto(int siteId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });
      final res = await _apiService.client.post('/api/hoarding/sites/$siteId/photo', data: formData);
      return HoardingSiteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to upload photo');
    }
  }

  Future<List<HoardingSiteLogModel>> getSiteLogs(int siteId) async {
    try {
      final res = await _apiService.client.get('/api/hoarding/sites/$siteId/logs');
      final data = (res.data['data'] as List<dynamic>? ?? []);
      return data.map((e) => HoardingSiteLogModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to load site logs');
    }
  }
}

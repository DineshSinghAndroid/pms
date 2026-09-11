import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/newspaper_entry_model.dart';
import '../models/newspaper_model.dart';
import '../models/newspaper_size_model.dart';
import '../models/wing_model.dart';
import '../services/api_service.dart';

class NewsTrackingRepository {
  final ApiService _apiService;

  NewsTrackingRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ==========================================
  // ENTRIES & MASTERS
  // ==========================================

  /// Fetch paginated news entries
  Future<Map<String, dynamic>> getEntries({
    String? search,
    int? wingId,
    int? newspaperId,
    int? sizeId,
    String? startDate,
    String? endDate,
    int page = 1,
    String? phone,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': 25,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (wingId != null && wingId > 0) queryParams['wing_id'] = wingId;
      if (newspaperId != null && newspaperId > 0) queryParams['newspaper_id'] = newspaperId;
      if (sizeId != null && sizeId > 0) queryParams['size_id'] = sizeId;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      final response = await _apiService.client.get(
        '/api/news-tracking/entries',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final List<dynamic> dataList = body['data'] as List<dynamic>? ?? [];
        final entries = dataList
            .map((item) => NewspaperEntryModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final pagination = body['pagination'] as Map<String, dynamic>? ?? {};
        final stats = body['stats'] as Map<String, dynamic>? ?? {};

        return {
          'entries': entries,
          'pagination': pagination,
          'stats': stats,
        };
      }
      return {'entries': <NewspaperEntryModel>[], 'pagination': {}, 'stats': {}};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return {'entries': <NewspaperEntryModel>[], 'pagination': {}, 'stats': {}};
      }
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Error loading news entries',
      );
    } catch (e) {
      return {'entries': <NewspaperEntryModel>[], 'pagination': {}, 'stats': {}};
    }
  }

  /// Fetch master items (Newspapers, Sizes, Wings)
  Future<Map<String, dynamic>> getMasters({String? phone}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      final response = await _apiService.client.get(
        '/api/news-tracking/masters',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        final data = body['data'] as Map<String, dynamic>? ?? {};
        final npList = (data['newspapers'] as List<dynamic>? ?? [])
            .map((e) => NewspaperModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final sizeList = (data['sizes'] as List<dynamic>? ?? [])
            .map((e) => NewspaperSizeModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final wingList = (data['wings'] as List<dynamic>? ?? [])
            .map((e) => WingModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return {
          'newspapers': npList,
          'sizes': sizeList,
          'wings': wingList,
        };
      }
      return {'newspapers': <NewspaperModel>[], 'sizes': <NewspaperSizeModel>[], 'wings': <WingModel>[]};
    } catch (e) {
      return {'newspapers': <NewspaperModel>[], 'sizes': <NewspaperSizeModel>[], 'wings': <WingModel>[]};
    }
  }

  /// Create new Newspaper Entry (with S3 file upload)
  Future<NewspaperEntryModel> createEntry({
    required String adName,
    required String publishDate,
    int? wingId,
    int? newspaperId,
    int? newspaperSizeId,
    String? link1,
    String? link2,
    String? remark,
    String? localFilePath,
    String? phone,
  }) async {
    final map = <String, dynamic>{
      'ad_name': adName,
      'publish_date': publishDate,
    };
    if (wingId != null) map['wing_id'] = wingId;
    if (newspaperId != null) map['newspaper_id'] = newspaperId;
    if (newspaperSizeId != null) map['newspaper_size_id'] = newspaperSizeId;
    if (link1 != null && link1.isNotEmpty) map['link1'] = link1;
    if (link2 != null && link2.isNotEmpty) map['link2'] = link2;
    if (remark != null && remark.isNotEmpty) map['remark'] = remark;
    if (phone != null && phone.isNotEmpty) map['phone'] = phone;

    if (localFilePath != null && localFilePath.isNotEmpty) {
      final file = File(localFilePath);
      if (await file.exists()) {
        final fileName = localFilePath.split(Platform.pathSeparator).last;
        final bytes = await file.readAsBytes();
        map['file_name'] = fileName;
        map['file_base64'] = base64Encode(bytes);
        map['file'] = MultipartFile.fromBytes(bytes, filename: fileName);
      }
    }

    final formData = FormData.fromMap(map);

    final response = await _apiService.client.post(
      '/api/news-tracking/entries',
      data: formData,
      queryParameters: phone != null ? {'phone': phone} : null,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data as Map<String, dynamic>;
      return NewspaperEntryModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data?['message'] ?? 'Failed to create news entry');
  }

  /// Update Newspaper Entry
  Future<NewspaperEntryModel> updateEntry({
    required int id,
    required String adName,
    required String publishDate,
    int? wingId,
    int? newspaperId,
    int? newspaperSizeId,
    String? link1,
    String? link2,
    String? remark,
    String? localFilePath,
    String? phone,
  }) async {
    final map = <String, dynamic>{
      'ad_name': adName,
      'publish_date': publishDate,
    };
    if (wingId != null) map['wing_id'] = wingId;
    if (newspaperId != null) map['newspaper_id'] = newspaperId;
    if (newspaperSizeId != null) map['newspaper_size_id'] = newspaperSizeId;
    if (link1 != null) map['link1'] = link1;
    if (link2 != null) map['link2'] = link2;
    if (remark != null) map['remark'] = remark;
    if (phone != null && phone.isNotEmpty) map['phone'] = phone;

    if (localFilePath != null && localFilePath.isNotEmpty) {
      final file = File(localFilePath);
      if (await file.exists()) {
        final fileName = localFilePath.split(Platform.pathSeparator).last;
        final bytes = await file.readAsBytes();
        map['file_name'] = fileName;
        map['file_base64'] = base64Encode(bytes);
        map['file'] = MultipartFile.fromBytes(bytes, filename: fileName);
      }
    }

    final formData = FormData.fromMap(map);

    final response = await _apiService.client.post(
      '/api/news-tracking/entries/$id',
      data: formData,
      queryParameters: phone != null ? {'phone': phone} : null,
    );

    if (response.statusCode == 200) {
      final body = response.data as Map<String, dynamic>;
      return NewspaperEntryModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data?['message'] ?? 'Failed to update news entry');
  }

  /// Delete Newspaper Entry
  Future<bool> deleteEntry(int id, {String? phone}) async {
    final response = await _apiService.client.delete(
      '/api/news-tracking/entries/$id',
      queryParameters: phone != null ? {'phone': phone} : null,
    );
    return response.statusCode == 200;
  }

  /// Quick create Newspaper
  Future<NewspaperModel> createNewspaper(String name, {String? phone}) async {
    final response = await _apiService.client.post(
      '/api/news-tracking/newspapers',
      data: {'name': name},
      queryParameters: phone != null ? {'phone': phone} : null,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data as Map<String, dynamic>;
      return NewspaperModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data?['message'] ?? 'Failed to add newspaper');
  }

  /// Quick create Newspaper Size
  Future<NewspaperSizeModel> createSize(String name, {String? phone}) async {
    final response = await _apiService.client.post(
      '/api/news-tracking/sizes',
      data: {'name': name},
      queryParameters: phone != null ? {'phone': phone} : null,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data as Map<String, dynamic>;
      return NewspaperSizeModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data?['message'] ?? 'Failed to add ad size');
  }
}

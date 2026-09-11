import 'package:equatable/equatable.dart';

import '../services/api_service.dart';
import 'newspaper_model.dart';
import 'newspaper_size_model.dart';
import 'user_model.dart';
import 'wing_model.dart';

class NewspaperEntryModel extends Equatable {
  final int id;
  final int? wingId;
  final int? newspaperId;
  final int? newspaperSizeId;
  final String adName;
  final String publishDate;
  final String? link1;
  final String? link2;
  final String? filePath;
  final String? fileUrl;
  final String? fileName;
  final String? fileDisk;
  final String? remark;
  final bool isActive;
  final int? createdByUserId;
  final WingModel? wing;
  final NewspaperModel? newspaper;
  final NewspaperSizeModel? newspaperSize;
  final UserModel? createdByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NewspaperEntryModel({
    required this.id,
    this.wingId,
    this.newspaperId,
    this.newspaperSizeId,
    required this.adName,
    required this.publishDate,
    this.link1,
    this.link2,
    this.filePath,
    this.fileUrl,
    this.fileName,
    this.fileDisk,
    this.remark,
    this.isActive = true,
    this.createdByUserId,
    this.wing,
    this.newspaper,
    this.newspaperSize,
    this.createdByUser,
    this.createdAt,
    this.updatedAt,
  });

  String? get computedFileUrl {
    if (fileUrl != null && fileUrl!.isNotEmpty) {
      if (fileUrl!.startsWith('http://') || fileUrl!.startsWith('https://')) {
        return fileUrl;
      }
      final clean = fileUrl!.startsWith('/') ? fileUrl!.substring(1) : fileUrl!;
      return '${ApiService.baseUrl}/$clean';
    }
    if (filePath != null && filePath!.isNotEmpty) {
      if (filePath!.startsWith('http://') || filePath!.startsWith('https://')) {
        return filePath;
      }
      final clean = filePath!.startsWith('/') ? filePath!.substring(1) : filePath!;
      if (clean.startsWith('storage/')) {
        return '${ApiService.baseUrl}/$clean';
      }
      return '${ApiService.baseUrl}/storage/$clean';
    }
    return null;
  }

  factory NewspaperEntryModel.fromJson(Map<String, dynamic> json) {
    return NewspaperEntryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      wingId: json['wing_id'] != null
          ? int.tryParse(json['wing_id'].toString())
          : null,
      newspaperId: json['newspaper_id'] != null
          ? int.tryParse(json['newspaper_id'].toString())
          : null,
      newspaperSizeId: json['newspaper_size_id'] != null
          ? int.tryParse(json['newspaper_size_id'].toString())
          : null,
      adName: json['ad_name'] as String? ?? '',
      publishDate: json['publish_date'] as String? ?? '',
      link1: json['link1'] as String?,
      link2: json['link2'] as String?,
      filePath: json['file_path'] as String?,
      fileUrl: json['file_url'] as String? ?? json['full_file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileDisk: json['file_disk'] as String?,
      remark: json['remark'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString())
          : null,
      wing: json['wing'] != null && json['wing'] is Map<String, dynamic>
          ? WingModel.fromJson(json['wing'] as Map<String, dynamic>)
          : null,
      newspaper: json['newspaper'] != null && json['newspaper'] is Map<String, dynamic>
          ? NewspaperModel.fromJson(json['newspaper'] as Map<String, dynamic>)
          : null,
      newspaperSize: json['newspaper_size'] != null && json['newspaper_size'] is Map<String, dynamic>
          ? NewspaperSizeModel.fromJson(json['newspaper_size'] as Map<String, dynamic>)
          : null,
      createdByUser: json['created_by_user'] != null && json['created_by_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['created_by_user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wing_id': wingId,
      'newspaper_id': newspaperId,
      'newspaper_size_id': newspaperSizeId,
      'ad_name': adName,
      'publish_date': publishDate,
      'link1': link1,
      'link2': link2,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_disk': fileDisk,
      'remark': remark,
      'is_active': isActive,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    wingId,
    newspaperId,
    newspaperSizeId,
    adName,
    publishDate,
    link1,
    link2,
    filePath,
    fileUrl,
    fileName,
    fileDisk,
    remark,
    isActive,
    createdByUserId,
    wing,
    newspaper,
    newspaperSize,
    createdAt,
  ];
}

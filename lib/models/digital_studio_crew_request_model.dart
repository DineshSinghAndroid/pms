import 'package:equatable/equatable.dart';
import 'digital_studio_asset_model.dart';
import 'user_model.dart';
import 'wing_model.dart';

class DigitalStudioCrewRequestModel extends Equatable {
  final int id;
  final String requestNumber;
  final int wingId;
  final WingModel? wing;
  final int? requestedByUserId;
  final UserModel? requestedBy;
  final String eventName;
  final int requiredCrewCount;
  final DateTime reportingDateTime;
  final DateTime eventEndTime;
  final String status; // pending, allotted, in_progress, completed, cancelled
  final String? remarks;
  final int? allottedByUserId;
  final UserModel? allottedBy;
  final DateTime? allottedAt;
  final List<UserModel> allottedEmployees;
  final List<DigitalStudioAssetModel> allottedAssets;
  final DateTime? workStartedAt;
  final int? workStartedByUserId;
  final double? workStartLatitude;
  final double? workStartLongitude;
  final double? workStartDistanceMeters;
  final bool workStartVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DigitalStudioCrewRequestModel({
    required this.id,
    required this.requestNumber,
    required this.wingId,
    this.wing,
    this.requestedByUserId,
    this.requestedBy,
    required this.eventName,
    this.requiredCrewCount = 1,
    required this.reportingDateTime,
    required this.eventEndTime,
    required this.status,
    this.remarks,
    this.allottedByUserId,
    this.allottedBy,
    this.allottedAt,
    this.allottedEmployees = const [],
    this.allottedAssets = const [],
    this.workStartedAt,
    this.workStartedByUserId,
    this.workStartLatitude,
    this.workStartLongitude,
    this.workStartDistanceMeters,
    this.workStartVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    final str = value.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return fallback ?? DateTime.now();
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  factory DigitalStudioCrewRequestModel.fromJson(Map<String, dynamic> json) {
    return DigitalStudioCrewRequestModel(
      id: json['id'] as int? ?? 0,
      requestNumber: json['request_number'] as String? ?? '',
      wingId: json['wing_id'] as int? ?? 0,
      wing: json['wing'] != null
          ? WingModel.fromJson(json['wing'] as Map<String, dynamic>)
          : null,
      requestedByUserId: json['requested_by_user_id'] as int?,
      requestedBy: json['requested_by'] != null
          ? UserModel.fromJson(json['requested_by'] as Map<String, dynamic>)
          : null,
      eventName: json['event_name'] as String? ?? '',
      requiredCrewCount: json['required_crew_count'] as int? ?? 1,
      reportingDateTime: _parseDateTime(json['reporting_date_time']),
      eventEndTime: _parseDateTime(
        json['event_end_time'],
        fallback: DateTime.now().add(const Duration(hours: 4)),
      ),
      status: json['status'] as String? ?? 'pending',
      remarks: json['remarks'] as String?,
      allottedByUserId: json['allotted_by_user_id'] as int?,
      allottedBy: json['allotted_by'] != null
          ? UserModel.fromJson(json['allotted_by'] as Map<String, dynamic>)
          : null,
      allottedAt: _parseNullableDateTime(json['allotted_at']),
      allottedEmployees: (json['allotted_employees'] as List<dynamic>?)
              ?.map((u) => UserModel.fromJson(u as Map<String, dynamic>))
              .toList() ??
          const [],
      allottedAssets: (json['allotted_assets'] as List<dynamic>?)
              ?.map(
                (a) => DigitalStudioAssetModel.fromJson(
                  a as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      workStartedAt: _parseNullableDateTime(json['work_started_at']),
      workStartedByUserId: json['work_started_by_user_id'] as int?,
      workStartLatitude: json['work_start_latitude'] != null
          ? double.tryParse(json['work_start_latitude'].toString())
          : null,
      workStartLongitude: json['work_start_longitude'] != null
          ? double.tryParse(json['work_start_longitude'].toString())
          : null,
      workStartDistanceMeters: json['work_start_distance_meters'] != null
          ? double.tryParse(json['work_start_distance_meters'].toString())
          : null,
      workStartVerified: json['work_start_verified'] as bool? ?? false,
      createdAt: _parseNullableDateTime(json['created_at']),
      updatedAt: _parseNullableDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_number': requestNumber,
      'wing_id': wingId,
      'wing': wing?.toJson(),
      'requested_by_user_id': requestedByUserId,
      'requested_by': requestedBy?.toJson(),
      'event_name': eventName,
      'required_crew_count': requiredCrewCount,
      'reporting_date_time': reportingDateTime.toIso8601String(),
      'event_end_time': eventEndTime.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'allotted_by_user_id': allottedByUserId,
      'allotted_by': allottedBy?.toJson(),
      'allotted_at': allottedAt?.toIso8601String(),
      'allotted_employees': allottedEmployees.map((e) => e.toJson()).toList(),
      'allotted_assets': allottedAssets.map((a) => a.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAllotted => status.toLowerCase() == 'allotted';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  @override
  List<Object?> get props => [
    id,
    requestNumber,
    wingId,
    wing,
    requestedByUserId,
    requestedBy,
    eventName,
    requiredCrewCount,
    reportingDateTime,
    eventEndTime,
    status,
    remarks,
    allottedByUserId,
    allottedBy,
    allottedAt,
    allottedEmployees,
    allottedAssets,
    createdAt,
    updatedAt,
  ];
}

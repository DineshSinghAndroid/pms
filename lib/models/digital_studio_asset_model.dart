import 'package:equatable/equatable.dart';
import 'user_model.dart';

class DigitalStudioAssetLogModel extends Equatable {
  final int id;
  final int assetId;
  final String action; // created, assigned, returned, reassigned, status_change, maintenance, damaged
  final int? userId;
  final UserModel? user;
  final int? actedByUserId;
  final UserModel? actedBy;
  final int? requestId;
  final String? remarks;
  final DateTime? createdAt;

  const DigitalStudioAssetLogModel({
    required this.id,
    required this.assetId,
    required this.action,
    this.userId,
    this.user,
    this.actedByUserId,
    this.actedBy,
    this.requestId,
    this.remarks,
    this.createdAt,
  });

  factory DigitalStudioAssetLogModel.fromJson(Map<String, dynamic> json) {
    return DigitalStudioAssetLogModel(
      id: json['id'] as int? ?? 0,
      assetId: json['asset_id'] as int? ?? 0,
      action: json['action'] as String? ?? 'created',
      userId: json['user_id'] as int?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      actedByUserId: json['acted_by_user_id'] as int?,
      actedBy: json['acted_by'] != null
          ? UserModel.fromJson(json['acted_by'] as Map<String, dynamic>)
          : null,
      requestId: json['request_id'] as int?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'action': action,
      'user_id': userId,
      'user': user?.toJson(),
      'acted_by_user_id': actedByUserId,
      'acted_by': actedBy?.toJson(),
      'request_id': requestId,
      'remarks': remarks,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    assetId,
    action,
    userId,
    user,
    actedByUserId,
    actedBy,
    requestId,
    remarks,
    createdAt,
  ];
}

class DigitalStudioAssetModel extends Equatable {
  static const List<String> categories = [
    'Camera',
    'Lens',
    'Audio/Mic',
    'Lighting',
    'Drone',
    'Gimbal/Tripod',
    'Memory Card',
    'Laptop/System',
    'Other',
  ];

  static const List<String> statuses = [
    'available',
    'assigned',
    'maintenance',
    'damaged',
  ];

  final int id;
  final String name;
  final String assetCode;
  final String category;
  final String? modelSerial;
  final String currentStatus; // available, assigned, maintenance, damaged
  final int? currentAssignedUserId;
  final UserModel? currentAssignedUser;
  final String? notes;
  final List<DigitalStudioAssetLogModel> logs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DigitalStudioAssetModel({
    required this.id,
    required this.name,
    required this.assetCode,
    required this.category,
    this.modelSerial,
    required this.currentStatus,
    this.currentAssignedUserId,
    this.currentAssignedUser,
    this.notes,
    this.logs = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DigitalStudioAssetModel.fromJson(Map<String, dynamic> json) {
    return DigitalStudioAssetModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      assetCode: json['asset_code'] as String? ?? '',
      category: json['category'] as String? ?? 'Camera',
      modelSerial: json['model_serial'] as String?,
      currentStatus: json['current_status'] as String? ?? 'available',
      currentAssignedUserId: json['current_assigned_user_id'] as int?,
      currentAssignedUser: json['current_assigned_user'] != null
          ? UserModel.fromJson(
              json['current_assigned_user'] as Map<String, dynamic>,
            )
          : null,
      notes: json['notes'] as String?,
      logs: (json['logs'] as List<dynamic>?)
              ?.map(
                (l) => DigitalStudioAssetLogModel.fromJson(
                  l as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
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
      'name': name,
      'asset_code': assetCode,
      'category': category,
      'model_serial': modelSerial,
      'current_status': currentStatus,
      'current_assigned_user_id': currentAssignedUserId,
      'current_assigned_user': currentAssignedUser?.toJson(),
      'notes': notes,
      'logs': logs.map((l) => l.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAvailable => currentStatus.toLowerCase() == 'available';
  bool get isAssigned => currentStatus.toLowerCase() == 'assigned';
  bool get isMaintenance => currentStatus.toLowerCase() == 'maintenance';
  bool get isDamaged => currentStatus.toLowerCase() == 'damaged';

  @override
  List<Object?> get props => [
    id,
    name,
    assetCode,
    category,
    modelSerial,
    currentStatus,
    currentAssignedUserId,
    currentAssignedUser,
    notes,
    logs,
    createdAt,
    updatedAt,
  ];
}

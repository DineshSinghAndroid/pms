import 'package:equatable/equatable.dart';

class HoardingSiteLogModel extends Equatable {
  final int id;
  final int hoardingSiteId;
  final int? userId;
  final String? userName;
  final String? userRole;
  final String? userPhone;
  final String event;
  final String? description;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime? createdAt;
  final String? createdAtIst;

  const HoardingSiteLogModel({
    required this.id,
    required this.hoardingSiteId,
    this.userId,
    this.userName,
    this.userRole,
    this.userPhone,
    required this.event,
    this.description,
    this.oldData,
    this.newData,
    this.createdAt,
    this.createdAtIst,
  });

  factory HoardingSiteLogModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    Map<String, dynamic>? parseMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    }

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

    return HoardingSiteLogModel(
      id: json['id'] as int? ?? 0,
      hoardingSiteId: json['hoarding_site_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      userName: user?['name'] as String?,
      userRole: user?['role'] as String?,
      userPhone: user?['phone'] as String?,
      event: json['event'] as String? ?? 'updated',
      description: json['description'] as String?,
      oldData: parseMap(json['old_data']),
      newData: parseMap(json['new_data']),
      createdAt: parsedDate,
      createdAtIst: json['created_at_ist'] as String? ?? json['created_at_formatted'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, hoardingSiteId, userId, event, description, createdAt, createdAtIst];
}

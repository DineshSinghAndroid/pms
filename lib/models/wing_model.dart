import 'package:equatable/equatable.dart';

class WingModel extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? location;
  final DateTime? createdAt;

  const WingModel({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.createdAt,
  });

  factory WingModel.fromJson(Map<String, dynamic> json) {
    return WingModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, code, location, createdAt];
}

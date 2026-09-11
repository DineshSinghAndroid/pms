import 'package:equatable/equatable.dart';

class NewspaperSizeModel extends Equatable {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;

  const NewspaperSizeModel({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
  });

  factory NewspaperSizeModel.fromJson(Map<String, dynamic> json) {
    return NewspaperSizeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, isActive, createdAt];
}

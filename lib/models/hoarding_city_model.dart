import 'package:equatable/equatable.dart';

class HoardingCityModel extends Equatable {
  final int id;
  final String name;
  final String? state;
  final bool isActive;
  final DateTime? createdAt;

  const HoardingCityModel({
    required this.id,
    required this.name,
    this.state,
    this.isActive = true,
    this.createdAt,
  });

  factory HoardingCityModel.fromJson(Map<String, dynamic> json) {
    return HoardingCityModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      state: json['state'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, name, state, isActive];
}

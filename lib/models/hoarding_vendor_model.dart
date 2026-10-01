import 'package:equatable/equatable.dart';

class HoardingVendorModel extends Equatable {
  final int id;
  final int? userId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final List<int> operatingCityIds;
  final bool isActive;
  final DateTime? createdAt;

  const HoardingVendorModel({
    required this.id,
    this.userId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.operatingCityIds = const [],
    this.isActive = true,
    this.createdAt,
  });

  factory HoardingVendorModel.fromJson(Map<String, dynamic> json) {
    List<int> cities = [];
    if (json['operating_city_ids'] is List) {
      cities = (json['operating_city_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    return HoardingVendorModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      operatingCityIds: cities,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'operating_city_ids': operatingCityIds,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, userId, name, phone, email, address, operatingCityIds, isActive];
}

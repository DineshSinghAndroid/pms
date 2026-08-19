import 'package:equatable/equatable.dart';

class VendorModel extends Equatable {
  final int id;
  final String name;
  final String mobile1;
  final String? mobile2;
  final String? email;
  final String? address;
  final bool isLoginAllowed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorModel({
    required this.id,
    required this.name,
    required this.mobile1,
    this.mobile2,
    this.email,
    this.address,
    required this.isLoginAllowed,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      mobile1: json['mobile1'] as String? ?? '',
      mobile2: json['mobile2'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isLoginAllowed: json['is_login_allowed'] as bool? ?? false,
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
      'mobile1': mobile1,
      'mobile2': mobile2,
      'email': email,
      'address': address,
      'is_login_allowed': isLoginAllowed,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mobile1,
        mobile2,
        email,
        address,
        isLoginAllowed,
        createdAt,
        updatedAt,
      ];
}

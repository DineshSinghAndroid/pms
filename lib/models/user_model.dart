import 'package:equatable/equatable.dart';
import 'wing_model.dart';
import 'category_model.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String role;
  final bool isActive;
  final List<WingModel> assignedWings;
  final List<CategoryModel> assignedCategories;
  final int? hoardingVendorId;
  final int? subStoreId;
  final String? subStoreName;
  final String? subStoreCode;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.assignedWings = const [],
    this.assignedCategories = const [],
    this.hoardingVendorId,
    this.subStoreId,
    this.subStoreName,
    this.subStoreCode,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'manager',
      isActive: json['is_active'] == null
          ? true
          : (json['is_active'] == true ||
              json['is_active'] == 1 ||
              json['is_active'] == '1'),
      assignedWings: (json['assigned_wings'] as List<dynamic>?)
              ?.map((w) => WingModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      assignedCategories: (json['assigned_categories'] as List<dynamic>?)
              ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          (json['assignedCategories'] as List<dynamic>?)
              ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      hoardingVendorId: json['hoarding_vendor_id'] != null
          ? int.tryParse(json['hoarding_vendor_id'].toString())
          : null,
      subStoreId: json['sub_store_id'] != null
          ? int.tryParse(json['sub_store_id'].toString())
          : (json['sub_store'] is Map ? (json['sub_store']['id'] as num?)?.toInt() : null),
      subStoreName: json['sub_store'] is Map ? json['sub_store']['name'] as String? : null,
      subStoreCode: json['sub_store'] is Map ? json['sub_store']['code'] as String? : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'assigned_wings': assignedWings.map((w) => w.toJson()).toList(),
      'assigned_categories': assignedCategories.map((c) => c.toJson()).toList(),
      'hoarding_vendor_id': hoardingVendorId,
      'sub_store_id': subStoreId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isSuperAdmin {
    final r = role.toLowerCase().trim();
    return r == 'superadmin' ||
        r == 'super admin' ||
        r == 'super_admin';
  }
  bool get isDesigner =>
      role == 'Designer' || role.toLowerCase() == 'designer';
  bool get isDigitalStudioIncharge =>
      role == 'Digital Studio Incharge' ||
      role.toLowerCase() == 'digital_studio_incharge';
  bool get isWingIncharge =>
      role == 'Wing Incharge' ||
      role.toLowerCase() == 'wing_incharge' ||
      role.toLowerCase() == 'counsellor' ||
      role.toLowerCase() == 'counselor';
  bool get isVendor => role.toLowerCase() == 'vendor';
  bool get isHoardingVendor {
    final r = role.toLowerCase().trim();
    return r == 'hoarding vendor' || r == 'hoarding_vendor';
  }
  bool get canAccessHoarding => isSuperAdmin || isManager || isHoardingVendor;
  bool get isManager => role.toLowerCase() == 'manager';
  bool get isStoreIncharge =>
      role == 'Store Incharge' ||
      role.toLowerCase() == 'store incharge' ||
      role.toLowerCase() == 'store_incharge';
  bool get isSubStoreIncharge {
    final r = role.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    return r == 'substoreincharge';
  }
  bool get canCreatePurchaseRequest =>
      isSuperAdmin || isManager || isWingIncharge || isStoreIncharge || isSubStoreIncharge;
  bool get isDigitalStoreIncharge {
    final r = role.toLowerCase().trim();
    return r == 'digital store incharge' ||
        r == 'digital_store_incharge' ||
        r == 'digital store inchrage';
  }
  bool get isDigitalStudioEmployee {
    final r = role.toLowerCase().trim();
    return r == 'digital studio employee' ||
        r == 'digital_studio_employee' ||
        r == 'studio employee' ||
        r == 'cameraman' ||
        r == 'video editor' ||
        r == 'drone operator' ||
        r == 'crew member' ||
        r == 'studio technician' ||
        r == 'photographer';
  }
  bool get canCreateStudioAssets =>
      isSuperAdmin || isManager || isDigitalStoreIncharge;
  bool get canManageStudio =>
      isSuperAdmin ||
      isManager ||
      isDigitalStudioIncharge ||
      isDigitalStoreIncharge;
  bool get canViewStudioModule =>
      !isDesigner &&
      (isSuperAdmin ||
          isManager ||
          isDigitalStudioIncharge ||
          isDigitalStoreIncharge ||
          isWingIncharge ||
          isDigitalStudioEmployee);

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    role,
    isActive,
    assignedWings,
    assignedCategories,
    hoardingVendorId,
    subStoreId,
    subStoreName,
    subStoreCode,
    createdAt,
  ];
}

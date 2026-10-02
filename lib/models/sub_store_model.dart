import 'package:equatable/equatable.dart';
import 'store_inventory_model.dart';

class SubStoreStatsModel extends Equatable {
  final int totalProducts;
  final int totalStock;
  final int inStockProducts;
  final int totalConsumed;

  const SubStoreStatsModel({
    this.totalProducts = 0,
    this.totalStock = 0,
    this.inStockProducts = 0,
    this.totalConsumed = 0,
  });

  factory SubStoreStatsModel.fromJson(Map<String, dynamic> json) {
    return SubStoreStatsModel(
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      inStockProducts: (json['in_stock_products'] as num?)?.toInt() ?? 0,
      totalConsumed: (json['total_consumed'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalProducts,
        totalStock,
        inStockProducts,
        totalConsumed,
      ];
}

class SubStoreStockModel extends Equatable {
  final int id;
  final int userId;
  final int productTypeId;
  final int currentStock;
  final int totalConsumed;
  final StoreProductModel? productType;

  const SubStoreStockModel({
    required this.id,
    required this.userId,
    required this.productTypeId,
    this.currentStock = 0,
    this.totalConsumed = 0,
    this.productType,
  });

  bool get isInStock => currentStock > 0;

  factory SubStoreStockModel.fromJson(Map<String, dynamic> json) {
    StoreProductModel? pType;
    if (json['product_type'] is Map<String, dynamic>) {
      pType = StoreProductModel.fromJson(json['product_type'] as Map<String, dynamic>);
    } else if (json['product_type'] is Map) {
      pType = StoreProductModel.fromJson(Map<String, dynamic>.from(json['product_type'] as Map));
    }

    return SubStoreStockModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      productTypeId: (json['product_type_id'] as num?)?.toInt() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      totalConsumed: (json['total_consumed'] as num?)?.toInt() ?? 0,
      productType: pType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productTypeId,
        currentStock,
        totalConsumed,
        productType,
      ];
}

class SubStoreStockLogModel extends Equatable {
  final int id;
  final int userId;
  final int productTypeId;
  final String action;
  final int quantityChange;
  final int currentStock;
  final String? referenceNumber;
  final String? remarks;
  final DateTime? createdAt;

  const SubStoreStockLogModel({
    required this.id,
    required this.userId,
    required this.productTypeId,
    required this.action,
    required this.quantityChange,
    required this.currentStock,
    this.referenceNumber,
    this.remarks,
    this.createdAt,
  });

  bool get isPositive => quantityChange > 0;

  String get actionLabel {
    switch (action) {
      case 'received_transfer':
        return '📥 Received from Main Store';
      case 'consumption':
        return '📋 Consumed';
      case 'return_to_main':
        return '📤 Returned to Main Store';
      case 'adjustment':
        return '📝 Adjustment';
      default:
        return action;
    }
  }

  factory SubStoreStockLogModel.fromJson(Map<String, dynamic> json) {
    return SubStoreStockLogModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      productTypeId: (json['product_type_id'] as num?)?.toInt() ?? 0,
      action: json['action'] as String? ?? 'transaction',
      quantityChange: (json['quantity_change'] as num?)?.toInt() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      referenceNumber: json['reference_number'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productTypeId,
        action,
        quantityChange,
        currentStock,
        referenceNumber,
        remarks,
        createdAt,
      ];
}

class SubStoreInchargeModel extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String role;
  final int? subStoreId;
  final String? subStoreName;

  const SubStoreInchargeModel({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    this.subStoreId,
    this.subStoreName,
  });

  factory SubStoreInchargeModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    if (json['sub_store'] is Map) {
      sName = json['sub_store']['name'] as String?;
    }
    return SubStoreInchargeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'Sub Store Incharge',
      subStoreId: (json['sub_store_id'] as num?)?.toInt(),
      subStoreName: sName,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, role, subStoreId, subStoreName];
}

class SubStoreEntityModel extends Equatable {
  final int id;
  final String name;
  final String? code;
  final int? wingId;
  final String? wingName;
  final String? location;
  final String? description;
  final bool isActive;
  final int inchargesCount;
  final List<SubStoreInchargeModel> incharges;

  const SubStoreEntityModel({
    required this.id,
    required this.name,
    this.code,
    this.wingId,
    this.wingName,
    this.location,
    this.description,
    this.isActive = true,
    this.inchargesCount = 0,
    this.incharges = const [],
  });

  factory SubStoreEntityModel.fromJson(Map<String, dynamic> json) {
    String? wName;
    if (json['wing'] is Map) {
      wName = json['wing']['name'] as String?;
    }

    final inchargesList = <SubStoreInchargeModel>[];
    if (json['incharges'] is List) {
      for (final item in json['incharges']) {
        if (item is Map<String, dynamic>) {
          inchargesList.add(SubStoreInchargeModel.fromJson(item));
        } else if (item is Map) {
          inchargesList.add(SubStoreInchargeModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SubStoreEntityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      wingId: (json['wing_id'] as num?)?.toInt(),
      wingName: wName,
      location: json['location'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1',
      inchargesCount: (json['incharges_count'] as num?)?.toInt() ?? inchargesList.length,
      incharges: inchargesList,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (code != null) 'code': code,
    if (wingId != null) 'wing_id': wingId,
    if (location != null) 'location': location,
    if (description != null) 'description': description,
    'is_active': isActive,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    wingId,
    wingName,
    location,
    description,
    isActive,
    inchargesCount,
    incharges,
  ];
}

class SubStoreConsumptionModel extends Equatable {
  final int id;
  final String? consumptionNumber;
  final int userId;
  final int productTypeId;
  final int? subStoreId;
  final int quantity;
  final String? purpose;
  final String? departmentOrWing;
  final String? remarks;
  final DateTime? consumedAt;
  final StoreProductModel? productType;
  final SubStoreInchargeModel? user;
  final SubStoreEntityModel? subStore;

  const SubStoreConsumptionModel({
    required this.id,
    this.consumptionNumber,
    required this.userId,
    required this.productTypeId,
    this.subStoreId,
    required this.quantity,
    this.purpose,
    this.departmentOrWing,
    this.remarks,
    this.consumedAt,
    this.productType,
    this.user,
    this.subStore,
  });

  factory SubStoreConsumptionModel.fromJson(Map<String, dynamic> json) {
    StoreProductModel? pType;
    if (json['product_type'] is Map<String, dynamic>) {
      pType = StoreProductModel.fromJson(json['product_type'] as Map<String, dynamic>);
    } else if (json['product_type'] is Map) {
      pType = StoreProductModel.fromJson(Map<String, dynamic>.from(json['product_type'] as Map));
    }

    SubStoreInchargeModel? u;
    if (json['user'] is Map<String, dynamic>) {
      u = SubStoreInchargeModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['user'] is Map) {
      u = SubStoreInchargeModel.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    }

    SubStoreEntityModel? s;
    if (json['sub_store'] is Map<String, dynamic>) {
      s = SubStoreEntityModel.fromJson(json['sub_store'] as Map<String, dynamic>);
    } else if (json['sub_store'] is Map) {
      s = SubStoreEntityModel.fromJson(Map<String, dynamic>.from(json['sub_store'] as Map));
    }

    return SubStoreConsumptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      consumptionNumber: json['consumption_number'] as String?,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      productTypeId: (json['product_type_id'] as num?)?.toInt() ?? 0,
      subStoreId: (json['sub_store_id'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      purpose: json['purpose'] as String?,
      departmentOrWing: json['department_or_wing'] as String?,
      remarks: json['remarks'] as String?,
      consumedAt: json['consumed_at'] != null
          ? DateTime.tryParse(json['consumed_at'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
      productType: pType,
      user: u,
      subStore: s,
    );
  }

  @override
  List<Object?> get props => [
    id,
    consumptionNumber,
    userId,
    productTypeId,
    subStoreId,
    quantity,
    purpose,
    departmentOrWing,
    remarks,
    consumedAt,
    productType,
    user,
    subStore,
  ];
}

import 'package:equatable/equatable.dart';

class StoreStatsModel extends Equatable {
  final int totalProducts;
  final int totalStock;
  final int inStockProducts;
  final int outOfStockProducts;

  const StoreStatsModel({
    this.totalProducts = 0,
    this.totalStock = 0,
    this.inStockProducts = 0,
    this.outOfStockProducts = 0,
  });

  factory StoreStatsModel.fromJson(Map<String, dynamic> json) {
    return StoreStatsModel(
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      inStockProducts: (json['in_stock_products'] as num?)?.toInt() ?? 0,
      outOfStockProducts: (json['out_of_stock_products'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalProducts,
        totalStock,
        inStockProducts,
        outOfStockProducts,
      ];
}

class StoreProductModel extends Equatable {
  final int id;
  final String name;
  final String? subName;
  final String? productCode;
  final String? description;
  final int currentStock;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;

  const StoreProductModel({
    required this.id,
    required this.name,
    this.subName,
    this.productCode,
    this.description,
    this.currentStock = 0,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
  });

  bool get isInStock => currentStock > 0;

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    String? catSlug;
    if (json['category'] is Map<String, dynamic>) {
      catName = json['category']['name'] as String?;
      catSlug = json['category']['slug'] as String?;
    }

    return StoreProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      subName: json['sub_name'] as String?,
      productCode: json['product_code'] as String?,
      description: json['description'] as String?,
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: catName,
      categorySlug: catSlug,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        subName,
        productCode,
        description,
        currentStock,
        categoryId,
        categoryName,
        categorySlug,
      ];
}

class ProductStockLogModel extends Equatable {
  final int id;
  final int productTypeId;
  final int? userId;
  final String? userName;
  final String? userRole;
  final String? userPhone;
  final String action;
  final int quantityChange;
  final int previousStock;
  final int currentStock;
  final String? referenceType;
  final String? referenceId;
  final String? referenceNumber;
  final String? remarks;
  final DateTime? createdAt;

  const ProductStockLogModel({
    required this.id,
    required this.productTypeId,
    this.userId,
    this.userName,
    this.userRole,
    this.userPhone,
    required this.action,
    required this.quantityChange,
    required this.previousStock,
    required this.currentStock,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.remarks,
    this.createdAt,
  });

  factory ProductStockLogModel.fromJson(Map<String, dynamic> json) {
    String? uName;
    String? uRole;
    String? uPhone;
    if (json['user'] is Map<String, dynamic>) {
      uName = json['user']['name'] as String?;
      uRole = json['user']['role'] as String?;
      uPhone = json['user']['phone'] as String?;
    }

    return ProductStockLogModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productTypeId: (json['product_type_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt(),
      userName: uName,
      userRole: uRole,
      userPhone: uPhone,
      action: json['action'] as String? ?? '',
      quantityChange: (json['quantity_change'] as num?)?.toInt() ?? 0,
      previousStock: (json['previous_stock'] as num?)?.toInt() ?? 0,
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id']?.toString(),
      referenceNumber: json['reference_number'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  String get actionLabel {
    switch (action) {
      case 'delivery_received':
        return 'Delivery Received';
      case 'manual_addition':
        return 'Manual Addition';
      case 'manual_deduction':
        return 'Manual Deduction';
      case 'damaged':
        return 'Damaged / Lost';
      case 'audit_correction':
        return 'Audit Correction';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  List<Object?> get props => [
        id,
        productTypeId,
        userId,
        userName,
        userRole,
        userPhone,
        action,
        quantityChange,
        previousStock,
        currentStock,
        referenceType,
        referenceId,
        referenceNumber,
        remarks,
        createdAt,
      ];
}

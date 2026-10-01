import 'package:equatable/equatable.dart';

import 'category_model.dart';

class ProductTypeModel extends Equatable {
  final int id;
  final int categoryId;
  final String name;
  final String? productCode;
  final String? subName;
  final String? description;
  final CategoryModel? category;
  final DateTime? createdAt;

  const ProductTypeModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.productCode,
    this.subName,
    this.description,
    this.category,
    this.createdAt,
  });

  factory ProductTypeModel.fromJson(Map<String, dynamic> json) {
    final sub = json['sub_name'] as String?;
    final desc = json['description'] as String?;
    return ProductTypeModel(
      id: json['id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      productCode: json['product_code'] as String?,
      subName: sub ?? desc,
      description: desc ?? sub,
      category:
          json['category'] != null && json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'product_code': productCode,
      'sub_name': subName,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    name,
    productCode,
    subName,
    description,
    category,
    createdAt,
  ];
}

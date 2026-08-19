import 'package:equatable/equatable.dart';

abstract class ProductTypeEvent extends Equatable {
  const ProductTypeEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductTypesEvent extends ProductTypeEvent {
  final int? categoryId;

  const FetchProductTypesEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class RefreshProductTypesEvent extends ProductTypeEvent {
  final int? categoryId;

  const RefreshProductTypesEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class CreateProductTypeEvent extends ProductTypeEvent {
  final Map<String, dynamic> payload;

  const CreateProductTypeEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateProductTypeEvent extends ProductTypeEvent {
  final int productTypeId;
  final Map<String, dynamic> payload;

  const UpdateProductTypeEvent({
    required this.productTypeId,
    required this.payload,
  });

  @override
  List<Object?> get props => [productTypeId, payload];
}

class DeleteProductTypeEvent extends ProductTypeEvent {
  final int productTypeId;

  const DeleteProductTypeEvent(this.productTypeId);

  @override
  List<Object?> get props => [productTypeId];
}

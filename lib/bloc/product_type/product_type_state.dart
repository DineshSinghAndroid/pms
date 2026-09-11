import 'package:equatable/equatable.dart';

import '../../models/product_type_model.dart';

abstract class ProductTypeState extends Equatable {
  const ProductTypeState();

  @override
  List<Object?> get props => [];
}

class ProductTypeInitial extends ProductTypeState {
  const ProductTypeInitial();
}

class ProductTypeLoading extends ProductTypeState {
  const ProductTypeLoading();
}

class ProductTypeLoaded extends ProductTypeState {
  final List<ProductTypeModel> productTypes;

  const ProductTypeLoaded({required this.productTypes});

  @override
  List<Object?> get props => [productTypes];
}

class ProductTypeError extends ProductTypeState {
  final String errorMessage;

  const ProductTypeError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

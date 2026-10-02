import 'package:equatable/equatable.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class FetchStoreInventoryEvent extends StoreEvent {
  final int? categoryId;
  final String? stockStatus;
  final String? search;

  const FetchStoreInventoryEvent({
    this.categoryId,
    this.stockStatus,
    this.search,
  });

  @override
  List<Object?> get props => [categoryId, stockStatus, search];
}

class RefreshStoreInventoryEvent extends StoreEvent {
  final int? categoryId;
  final String? stockStatus;
  final String? search;

  const RefreshStoreInventoryEvent({
    this.categoryId,
    this.stockStatus,
    this.search,
  });

  @override
  List<Object?> get props => [categoryId, stockStatus, search];
}

class AdjustStockEvent extends StoreEvent {
  final int productId;
  final String adjustmentType;
  final int quantity;
  final String remarks;

  const AdjustStockEvent({
    required this.productId,
    required this.adjustmentType,
    required this.quantity,
    required this.remarks,
  });

  @override
  List<Object?> get props => [productId, adjustmentType, quantity, remarks];
}

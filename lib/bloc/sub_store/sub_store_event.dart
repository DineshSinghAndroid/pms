import 'package:equatable/equatable.dart';

abstract class SubStoreEvent extends Equatable {
  const SubStoreEvent();

  @override
  List<Object?> get props => [];
}

class FetchSubStoreInventoryEvent extends SubStoreEvent {
  final String? stockStatus;
  final String? search;
  final int? subStoreId;

  const FetchSubStoreInventoryEvent({
    this.stockStatus,
    this.search,
    this.subStoreId,
  });

  @override
  List<Object?> get props => [stockStatus, search, subStoreId];
}

class RefreshSubStoreInventoryEvent extends SubStoreEvent {
  final String? stockStatus;
  final String? search;
  final int? subStoreId;

  const RefreshSubStoreInventoryEvent({
    this.stockStatus,
    this.search,
    this.subStoreId,
  });

  @override
  List<Object?> get props => [stockStatus, search, subStoreId];
}

class RecordSubStoreConsumptionEvent extends SubStoreEvent {
  final int productTypeId;
  final int quantity;
  final String purpose;
  final String? department;
  final String? remarks;

  const RecordSubStoreConsumptionEvent({
    required this.productTypeId,
    required this.quantity,
    required this.purpose,
    this.department,
    this.remarks,
  });

  @override
  List<Object?> get props => [
        productTypeId,
        quantity,
        purpose,
        department,
        remarks,
      ];
}

class FetchSubStoresListEvent extends SubStoreEvent {
  const FetchSubStoresListEvent();
}

class CreateSubStoreEntityEvent extends SubStoreEvent {
  final Map<String, dynamic> data;
  const CreateSubStoreEntityEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateSubStoreEntityEvent extends SubStoreEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateSubStoreEntityEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteSubStoreEntityEvent extends SubStoreEvent {
  final int id;
  const DeleteSubStoreEntityEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchSubStoreConsumptionsEvent extends SubStoreEvent {
  final int? subStoreId;
  final int? userId;
  final String? search;

  const FetchSubStoreConsumptionsEvent({
    this.subStoreId,
    this.userId,
    this.search,
  });

  @override
  List<Object?> get props => [subStoreId, userId, search];
}

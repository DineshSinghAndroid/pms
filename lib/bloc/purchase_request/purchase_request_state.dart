import 'package:equatable/equatable.dart';
import '../../models/purchase_request_model.dart';

abstract class PurchaseRequestState extends Equatable {
  const PurchaseRequestState();

  @override
  List<Object?> get props => [];
}

class PurchaseRequestInitial extends PurchaseRequestState {
  const PurchaseRequestInitial();
}

class PurchaseRequestLoading extends PurchaseRequestState {
  const PurchaseRequestLoading();
}

class PurchaseRequestLoaded extends PurchaseRequestState {
  final List<PurchaseRequestModel> requests;

  const PurchaseRequestLoaded({required this.requests});

  @override
  List<Object?> get props => [requests];
}

class PurchaseRequestError extends PurchaseRequestState {
  final String errorMessage;

  const PurchaseRequestError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

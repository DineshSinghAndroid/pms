import 'package:equatable/equatable.dart';

abstract class PurchaseRequestEvent extends Equatable {
  const PurchaseRequestEvent();

  @override
  List<Object?> get props => [];
}

class FetchPurchaseRequestsEvent extends PurchaseRequestEvent {
  final int? designerId;
  final String? phone;
  final String? status;
  final int? wingId;

  const FetchPurchaseRequestsEvent({
    this.designerId,
    this.phone,
    this.status,
    this.wingId,
  });

  @override
  List<Object?> get props => [designerId, phone, status, wingId];
}

class CreatePurchaseRequestEvent extends PurchaseRequestEvent {
  final Map<String, dynamic> payload;

  const CreatePurchaseRequestEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class AssignDesignerEvent extends PurchaseRequestEvent {
  final int prId;
  final int designerId;

  const AssignDesignerEvent({required this.prId, required this.designerId});

  @override
  List<Object?> get props => [prId, designerId];
}

class StartWorkEvent extends PurchaseRequestEvent {
  final int prId;
  final String? phone;
  final int? designerId;

  const StartWorkEvent({required this.prId, this.phone, this.designerId});

  @override
  List<Object?> get props => [prId, phone, designerId];
}

class SubmitWorkEvent extends PurchaseRequestEvent {
  final int prId;
  final String? remarks;
  final String? artworkPath;
  final String? artworkName;
  final List<int>? fileBytes;
  final String? phone;
  final int? designerId;

  const SubmitWorkEvent({
    required this.prId,
    this.remarks,
    this.artworkPath,
    this.artworkName,
    this.fileBytes,
    this.phone,
    this.designerId,
  });

  @override
  List<Object?> get props => [
    prId,
    remarks,
    artworkPath,
    artworkName,
    fileBytes,
    phone,
    designerId,
  ];
}

class ApprovePREvent extends PurchaseRequestEvent {
  final int prId;
  final String? remarks;
  final String? phone;

  const ApprovePREvent({required this.prId, this.remarks, this.phone});

  @override
  List<Object?> get props => [prId, remarks, phone];
}

class RejectRevisionPREvent extends PurchaseRequestEvent {
  final int prId;
  final String remarks;
  final String? phone;

  const RejectRevisionPREvent({
    required this.prId,
    required this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [prId, remarks, phone];
}

class PostItPREvent extends PurchaseRequestEvent {
  final int prId;
  final String? remarks;
  final String? phone;

  const PostItPREvent({required this.prId, this.remarks, this.phone});

  @override
  List<Object?> get props => [prId, remarks, phone];
}

class CancelPostPREvent extends PurchaseRequestEvent {
  final int prId;
  final String? phone;

  const CancelPostPREvent({required this.prId, this.phone});

  @override
  List<Object?> get props => [prId, phone];
}

class CancelPrintPREvent extends PurchaseRequestEvent {
  final int prId;
  final String? phone;

  const CancelPrintPREvent({required this.prId, this.phone});

  @override
  List<Object?> get props => [prId, phone];
}

class DeletePurchaseRequestEvent extends PurchaseRequestEvent {
  final int prId;

  const DeletePurchaseRequestEvent(this.prId);

  @override
  List<Object?> get props => [prId];
}

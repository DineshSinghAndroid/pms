import 'package:equatable/equatable.dart';

abstract class DigitalStudioEvent extends Equatable {
  const DigitalStudioEvent();

  @override
  List<Object?> get props => [];
}

class FetchDigitalStudioDataEvent extends DigitalStudioEvent {
  final String? phone;
  final int? wingId;

  const FetchDigitalStudioDataEvent({this.phone, this.wingId});

  @override
  List<Object?> get props => [phone, wingId];
}

class RefreshDigitalStudioEvent extends DigitalStudioEvent {
  final String? phone;
  final int? wingId;

  const RefreshDigitalStudioEvent({this.phone, this.wingId});

  @override
  List<Object?> get props => [phone, wingId];
}

class CreateAssetEvent extends DigitalStudioEvent {
  final Map<String, dynamic> payload;
  final String? phone;

  const CreateAssetEvent({required this.payload, this.phone});

  @override
  List<Object?> get props => [payload, phone];
}

class AssignAssetEvent extends DigitalStudioEvent {
  final int assetId;
  final int userId;
  final int? requestId;
  final String? remarks;
  final String? phone;

  const AssignAssetEvent({
    required this.assetId,
    required this.userId,
    this.requestId,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [assetId, userId, requestId, remarks, phone];
}

class ReturnAssetEvent extends DigitalStudioEvent {
  final int assetId;
  final String? remarks;
  final String? phone;

  const ReturnAssetEvent({
    required this.assetId,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [assetId, remarks, phone];
}

class ReassignAssetEvent extends DigitalStudioEvent {
  final int assetId;
  final int userId;
  final int? requestId;
  final String? remarks;
  final String? phone;

  const ReassignAssetEvent({
    required this.assetId,
    required this.userId,
    this.requestId,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [assetId, userId, requestId, remarks, phone];
}

class UpdateAssetStatusEvent extends DigitalStudioEvent {
  final int assetId;
  final String status;
  final String? remarks;
  final String? phone;

  const UpdateAssetStatusEvent({
    required this.assetId,
    required this.status,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [assetId, status, remarks, phone];
}

class CreateCrewRequestEvent extends DigitalStudioEvent {
  final Map<String, dynamic> payload;
  final String? phone;

  const CreateCrewRequestEvent({required this.payload, this.phone});

  @override
  List<Object?> get props => [payload, phone];
}

class AllotCrewRequestEvent extends DigitalStudioEvent {
  final int requestId;
  final List<int> employeeIds;
  final List<int> assetIds;
  final String? remarks;
  final String? phone;

  const AllotCrewRequestEvent({
    required this.requestId,
    required this.employeeIds,
    this.assetIds = const [],
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [requestId, employeeIds, assetIds, remarks, phone];
}

class UpdateCrewRequestStatusEvent extends DigitalStudioEvent {
  final int requestId;
  final String status;
  final String? phone;

  const UpdateCrewRequestStatusEvent({
    required this.requestId,
    required this.status,
    this.phone,
  });

  @override
  List<Object?> get props => [requestId, status, phone];
}

import 'package:equatable/equatable.dart';
import 'package:pms/repositories/print_order_repository.dart';

abstract class PrintOrderEvent extends Equatable {
  const PrintOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchPrintOrders extends PrintOrderEvent {
  final String? phone;
  final int? vendorId;
  final int? wingId;
  final String? status;
  final String? search;
  final int? purchaseRequestId;

  const FetchPrintOrders({
    this.phone,
    this.vendorId,
    this.wingId,
    this.status,
    this.search,
    this.purchaseRequestId,
  });

  @override
  List<Object?> get props => [
    phone,
    vendorId,
    wingId,
    status,
    search,
    purchaseRequestId,
  ];
}

class CreatePrintOrderEvent extends PrintOrderEvent {
  final int vendorId;
  final int? purchaseRequestId;
  final int? wingId;
  final String? expectedDeliveryDate;
  final String? expectedDeliveryTime;
  final String? requesterRemarks;
  final String? printOrderRemarks;
  final String? phone;
  final List<CreatePrintOrderItemParam> items;

  const CreatePrintOrderEvent({
    required this.vendorId,
    this.purchaseRequestId,
    this.wingId,
    this.expectedDeliveryDate,
    this.expectedDeliveryTime,
    this.requesterRemarks,
    this.printOrderRemarks,
    this.phone,
    required this.items,
  });

  @override
  List<Object?> get props => [
    vendorId,
    purchaseRequestId,
    wingId,
    expectedDeliveryDate,
    expectedDeliveryTime,
    requesterRemarks,
    printOrderRemarks,
    phone,
    items,
  ];
}

class UpdatePrintOrderStatusEvent extends PrintOrderEvent {
  final int printOrderId;
  final String status;
  final String? remarks;
  final String? phone;
  final List<int>? fileBytes;
  final String? fileName;

  const UpdatePrintOrderStatusEvent({
    required this.printOrderId,
    required this.status,
    this.remarks,
    this.phone,
    this.fileBytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [
    printOrderId,
    status,
    remarks,
    phone,
    fileBytes,
    fileName,
  ];
}

class FetchDeliveryLogsEvent extends PrintOrderEvent {
  final String? status;
  final String? search;

  const FetchDeliveryLogsEvent({this.status, this.search});

  @override
  List<Object?> get props => [status, search];
}

class RecordDeliveryEvent extends PrintOrderEvent {
  final int printOrderId;
  final String challanNumber;
  final String? deliveryDate;
  final String? remarks;
  final String? phone;
  final List<Map<String, dynamic>> items;

  const RecordDeliveryEvent({
    required this.printOrderId,
    required this.challanNumber,
    this.deliveryDate,
    this.remarks,
    this.phone,
    required this.items,
  });

  @override
  List<Object?> get props => [
    printOrderId,
    challanNumber,
    deliveryDate,
    remarks,
    phone,
    items,
  ];
}

class SubmitQuotationEvent extends PrintOrderEvent {
  final int printOrderId;
  final List<Map<String, dynamic>> items;
  final double? gstRate;
  final String? quoteRemarks;
  final String? phone;

  const SubmitQuotationEvent({
    required this.printOrderId,
    required this.items,
    this.gstRate,
    this.quoteRemarks,
    this.phone,
  });

  @override
  List<Object?> get props => [
    printOrderId,
    items,
    gstRate,
    quoteRemarks,
    phone,
  ];
}

class ApproveQuotationEvent extends PrintOrderEvent {
  final int printOrderId;
  final String? phone;

  const ApproveQuotationEvent({
    required this.printOrderId,
    this.phone,
  });

  @override
  List<Object?> get props => [printOrderId, phone];
}

class RequestQuotationRevisionEvent extends PrintOrderEvent {
  final int printOrderId;
  final String remarks;
  final String? phone;

  const RequestQuotationRevisionEvent({
    required this.printOrderId,
    required this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [printOrderId, remarks, phone];
}

class ReassignVendorEvent extends PrintOrderEvent {
  final int printOrderId;
  final int vendorId;
  final String? remarks;
  final String? phone;

  const ReassignVendorEvent({
    required this.printOrderId,
    required this.vendorId,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [printOrderId, vendorId, remarks, phone];
}

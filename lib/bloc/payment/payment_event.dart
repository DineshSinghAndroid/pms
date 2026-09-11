import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class FetchPaymentsEvent extends PaymentEvent {
  final String? search;
  final int? vendorId;
  final int? wingId;

  const FetchPaymentsEvent({this.search, this.vendorId, this.wingId});

  @override
  List<Object?> get props => [search, vendorId, wingId];
}

class FetchEligiblePaymentItemsEvent extends PaymentEvent {
  final String? search;
  final int? vendorId;
  final int? wingId;

  const FetchEligiblePaymentItemsEvent({
    this.search,
    this.vendorId,
    this.wingId,
  });

  @override
  List<Object?> get props => [search, vendorId, wingId];
}

class RecordPaymentEvent extends PaymentEvent {
  final int printOrderId;
  final int? printOrderItemId;
  final String invoiceNumber;
  final String paymentDate;
  final double? amount;
  final String? paymentMethod;
  final String? transactionReference;
  final String? remarks;
  final String? phone;

  const RecordPaymentEvent({
    required this.printOrderId,
    this.printOrderItemId,
    required this.invoiceNumber,
    required this.paymentDate,
    this.amount,
    this.paymentMethod,
    this.transactionReference,
    this.remarks,
    this.phone,
  });

  @override
  List<Object?> get props => [
        printOrderId,
        printOrderItemId,
        invoiceNumber,
        paymentDate,
        amount,
        paymentMethod,
        transactionReference,
        remarks,
        phone,
      ];
}

class FetchPaymentDetailsEvent extends PaymentEvent {
  final int paymentId;

  const FetchPaymentDetailsEvent(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

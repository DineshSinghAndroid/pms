import 'package:equatable/equatable.dart';
import 'package:pms/models/print_order_delivery_model.dart';
import 'package:pms/models/print_order_model.dart';

abstract class PrintOrderState extends Equatable {
  const PrintOrderState();

  List<PrintOrderModel> get printOrdersList => const [];
  List<PrintOrderDeliveryModel> get deliveriesList => const [];

  @override
  List<Object?> get props => [];
}

class PrintOrderInitial extends PrintOrderState {}

class PrintOrderLoading extends PrintOrderState {}

class PrintOrderLoaded extends PrintOrderState {
  final List<PrintOrderModel> printOrders;
  final List<PrintOrderDeliveryModel> deliveries;
  final String? successMessage;

  const PrintOrderLoaded({
    required this.printOrders,
    this.deliveries = const [],
    this.successMessage,
  });

  @override
  List<PrintOrderModel> get printOrdersList => printOrders;

  @override
  List<PrintOrderDeliveryModel> get deliveriesList => deliveries;

  @override
  List<Object?> get props => [printOrders, deliveries, successMessage];
}

class PrintOrderError extends PrintOrderState {
  final String message;

  const PrintOrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class PrintOrderActionSuccess extends PrintOrderState {
  final String message;
  final PrintOrderModel printOrder;

  const PrintOrderActionSuccess({
    required this.message,
    required this.printOrder,
  });

  @override
  List<Object?> get props => [message, printOrder];
}

class DeliveryLogsLoaded extends PrintOrderState {
  final List<PrintOrderDeliveryModel> deliveries;
  final List<PrintOrderModel> printOrders;
  final String? successMessage;

  const DeliveryLogsLoaded({
    required this.deliveries,
    this.printOrders = const [],
    this.successMessage,
  });

  @override
  List<PrintOrderModel> get printOrdersList => printOrders;

  @override
  List<PrintOrderDeliveryModel> get deliveriesList => deliveries;

  @override
  List<Object?> get props => [deliveries, printOrders, successMessage];
}

class DeliveryRecordedSuccess extends PrintOrderState {
  final String message;
  final PrintOrderDeliveryModel? delivery;
  final PrintOrderModel? printOrder;
  final bool isCompleted;

  const DeliveryRecordedSuccess({
    required this.message,
    this.delivery,
    this.printOrder,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [message, delivery, printOrder, isCompleted];
}

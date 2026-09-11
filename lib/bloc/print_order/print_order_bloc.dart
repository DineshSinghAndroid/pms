import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_delivery_model.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/repositories/print_order_repository.dart';

class PrintOrderBloc extends Bloc<PrintOrderEvent, PrintOrderState> {
  final PrintOrderRepository _repository;
  List<PrintOrderModel> _cachedOrders = [];
  List<PrintOrderDeliveryModel> _cachedDeliveries = [];

  PrintOrderBloc({PrintOrderRepository? repository})
    : _repository = repository ?? PrintOrderRepository(),
      super(PrintOrderInitial()) {
    on<FetchPrintOrders>(_onFetchPrintOrders);
    on<CreatePrintOrderEvent>(_onCreatePrintOrder);
    on<UpdatePrintOrderStatusEvent>(_onUpdatePrintOrderStatus);
    on<FetchDeliveryLogsEvent>(_onFetchDeliveryLogs);
    on<RecordDeliveryEvent>(_onRecordDelivery);
  }

  Future<void> _onFetchDeliveryLogs(
    FetchDeliveryLogsEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final logs = await _repository.getDeliveryLogs(
        status: event.status,
        search: event.search,
      );
      _cachedDeliveries = logs;
      emit(DeliveryLogsLoaded(
        deliveries: _cachedDeliveries,
        printOrders: _cachedOrders,
      ));
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRecordDelivery(
    RecordDeliveryEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final result = await _repository.recordDelivery(
        printOrderId: event.printOrderId,
        challanNumber: event.challanNumber,
        deliveryDate: event.deliveryDate,
        remarks: event.remarks,
        phone: event.phone,
        items: event.items,
      );

      final message =
          result['message']?.toString() ?? 'Delivery recorded successfully!';
      emit(
        DeliveryRecordedSuccess(
          message: message,
          delivery: result['delivery'],
          printOrder: result['print_order'],
          isCompleted: result['is_completed'] ?? false,
        ),
      );

      // Refresh delivery logs
      _cachedDeliveries = await _repository.getDeliveryLogs();
      emit(DeliveryLogsLoaded(
        deliveries: _cachedDeliveries,
        printOrders: _cachedOrders,
        successMessage: message,
      ));
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchPrintOrders(
    FetchPrintOrders event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final orders = await _repository.getPrintOrders(
        phone: event.phone,
        vendorId: event.vendorId,
        wingId: event.wingId,
        status: event.status,
        search: event.search,
        purchaseRequestId: event.purchaseRequestId,
      );
      _cachedOrders = orders;
      emit(PrintOrderLoaded(
        printOrders: _cachedOrders,
        deliveries: _cachedDeliveries,
      ));
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePrintOrder(
    CreatePrintOrderEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.createPrintOrder(
        vendorId: event.vendorId,
        purchaseRequestId: event.purchaseRequestId,
        wingId: event.wingId,
        expectedDeliveryDate: event.expectedDeliveryDate,
        expectedDeliveryTime: event.expectedDeliveryTime,
        requesterRemarks: event.requesterRemarks,
        printOrderRemarks: event.printOrderRemarks,
        phone: event.phone,
        items: event.items,
      );
      emit(
        PrintOrderActionSuccess(
          message: 'Print Order ${order.poNumber} created and dispatched!',
          printOrder: order,
        ),
      );
      // Refresh list
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage:
              'Print Order ${order.poNumber} created and dispatched!',
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdatePrintOrderStatus(
    UpdatePrintOrderStatusEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.updatePrintOrderStatus(
        event.printOrderId,
        status: event.status,
        remarks: event.remarks,
        phone: event.phone,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
      );
      emit(
        PrintOrderActionSuccess(
          message: "Print Order status updated to '${event.status}'!",
          printOrder: order,
        ),
      );
      // Refresh list
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage: "Print Order status updated to '${event.status}'!",
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

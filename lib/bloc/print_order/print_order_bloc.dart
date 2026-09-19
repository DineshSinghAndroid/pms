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
    on<SubmitQuotationEvent>(_onSubmitQuotation);
    on<ApproveQuotationEvent>(_onApproveQuotation);
    on<RequestQuotationRevisionEvent>(_onRequestQuotationRevision);
    on<ReassignVendorEvent>(_onReassignVendor);
  }

  Future<void> _onSubmitQuotation(
    SubmitQuotationEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.submitQuotation(
        event.printOrderId,
        items: event.items,
        gstRate: event.gstRate,
        quoteRemarks: event.quoteRemarks,
        phone: event.phone,
      );
      emit(
        PrintOrderActionSuccess(
          message: 'Price quotation submitted successfully to Admin & Manager!',
          printOrder: order,
        ),
      );
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage: 'Price quotation submitted successfully!',
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApproveQuotation(
    ApproveQuotationEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.approveQuotation(
        event.printOrderId,
        phone: event.phone,
      );
      emit(
        PrintOrderActionSuccess(
          message: 'Quotation approved! Order is now in production.',
          printOrder: order,
        ),
      );
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage: 'Quotation approved successfully!',
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestQuotationRevision(
    RequestQuotationRevisionEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.requestQuotationRevision(
        event.printOrderId,
        remarks: event.remarks,
        phone: event.phone,
      );
      emit(
        PrintOrderActionSuccess(
          message: 'Quotation revision request sent to vendor.',
          printOrder: order,
        ),
      );
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage: 'Quotation revision request sent!',
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReassignVendor(
    ReassignVendorEvent event,
    Emitter<PrintOrderState> emit,
  ) async {
    emit(PrintOrderLoading());
    try {
      final order = await _repository.reassignVendor(
        event.printOrderId,
        vendorId: event.vendorId,
        remarks: event.remarks,
        phone: event.phone,
      );
      emit(
        PrintOrderActionSuccess(
          message: 'Order reassigned to new vendor for fresh quotation.',
          printOrder: order,
        ),
      );
      _cachedOrders = await _repository.getPrintOrders(phone: event.phone);
      emit(
        PrintOrderLoaded(
          printOrders: _cachedOrders,
          deliveries: _cachedDeliveries,
          successMessage: 'Order reassigned successfully!',
        ),
      );
    } catch (e) {
      emit(PrintOrderError(e.toString().replaceAll('Exception: ', '')));
    }
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

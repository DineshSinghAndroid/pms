import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository;

  PaymentBloc({required this.repository}) : super(PaymentInitial()) {
    on<FetchPaymentsEvent>(_onFetchPayments);
    on<FetchEligiblePaymentItemsEvent>(_onFetchEligiblePaymentItems);
    on<RecordPaymentEvent>(_onRecordPayment);
    on<FetchPaymentDetailsEvent>(_onFetchPaymentDetails);
  }

  Future<void> _onFetchPayments(
    FetchPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final current = state is PaymentLoaded
        ? (state as PaymentLoaded)
        : const PaymentLoaded();
    emit(PaymentLoading());
    try {
      final payments = await repository.getPayments(
        search: event.search,
        vendorId: event.vendorId,
        wingId: event.wingId,
      );
      emit(current.copyWith(
        payments: payments,
        errorMessage: null,
      ));
    } catch (e) {
      emit(PaymentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchEligiblePaymentItems(
    FetchEligiblePaymentItemsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final current = state is PaymentLoaded
        ? (state as PaymentLoaded)
        : const PaymentLoaded();
    try {
      final items = await repository.getEligibleItems(
        search: event.search,
        vendorId: event.vendorId,
        wingId: event.wingId,
      );
      emit(current.copyWith(
        eligibleItems: items,
        errorMessage: null,
      ));
    } catch (e) {
      emit(current.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRecordPayment(
    RecordPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final current = state is PaymentLoaded
        ? (state as PaymentLoaded)
        : const PaymentLoaded();
    emit(current.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final payment = await repository.recordPayment(
        printOrderId: event.printOrderId,
        printOrderItemId: event.printOrderItemId,
        invoiceNumber: event.invoiceNumber,
        paymentDate: event.paymentDate,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        transactionReference: event.transactionReference,
        remarks: event.remarks,
        phone: event.phone,
      );

      // Refresh payments and eligible list
      final payments = await repository.getPayments();
      final items = await repository.getEligibleItems();

      emit(PaymentActionSuccess(
        'Payment ${payment.paymentNumber} recorded successfully!',
        payment,
      ));

      emit(current.copyWith(
        payments: payments,
        eligibleItems: items,
        isSubmitting: false,
        successMessage: 'Payment recorded successfully',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onFetchPaymentDetails(
    FetchPaymentDetailsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    final current = state is PaymentLoaded
        ? (state as PaymentLoaded)
        : const PaymentLoaded();
    try {
      final details = await repository.getPaymentDetails(event.paymentId);
      emit(current.copyWith(
        selectedPaymentDetails: details,
        errorMessage: null,
      ));
    } catch (e) {
      emit(current.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}

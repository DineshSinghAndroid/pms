import 'package:equatable/equatable.dart';
import 'package:pms/models/eligible_payment_item_model.dart';
import 'package:pms/models/payment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final List<ProductPaymentModel> payments;
  final List<EligiblePaymentItemModel> eligibleItems;
  final ProductPaymentModel? selectedPaymentDetails;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const PaymentLoaded({
    this.payments = const [],
    this.eligibleItems = const [],
    this.selectedPaymentDetails,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  PaymentLoaded copyWith({
    List<ProductPaymentModel>? payments,
    List<EligiblePaymentItemModel>? eligibleItems,
    ProductPaymentModel? selectedPaymentDetails,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return PaymentLoaded(
      payments: payments ?? this.payments,
      eligibleItems: eligibleItems ?? this.eligibleItems,
      selectedPaymentDetails:
          selectedPaymentDetails ?? this.selectedPaymentDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        payments,
        eligibleItems,
        selectedPaymentDetails,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentActionSuccess extends PaymentState {
  final String message;
  final ProductPaymentModel payment;

  const PaymentActionSuccess(this.message, this.payment);

  @override
  List<Object?> get props => [message, payment];
}

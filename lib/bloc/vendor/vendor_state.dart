import 'package:equatable/equatable.dart';
import '../../models/vendor_model.dart';

abstract class VendorState extends Equatable {
  const VendorState();

  @override
  List<Object?> get props => [];
}

class VendorInitial extends VendorState {
  const VendorInitial();
}

class VendorLoading extends VendorState {
  const VendorLoading();
}

class VendorLoaded extends VendorState {
  final List<VendorModel> vendors;

  const VendorLoaded({required this.vendors});

  @override
  List<Object?> get props => [vendors];
}

class VendorError extends VendorState {
  final String errorMessage;

  const VendorError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

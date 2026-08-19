import 'package:equatable/equatable.dart';

abstract class VendorEvent extends Equatable {
  const VendorEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch list of all vendors
class FetchVendorsEvent extends VendorEvent {
  const FetchVendorsEvent();
}

/// Pull-to-refresh vendors list
class RefreshVendorsEvent extends VendorEvent {
  const RefreshVendorsEvent();
}

/// Create a new vendor
class CreateVendorEvent extends VendorEvent {
  final Map<String, dynamic> payload;

  const CreateVendorEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

/// Update an existing vendor
class UpdateVendorEvent extends VendorEvent {
  final int vendorId;
  final Map<String, dynamic> payload;

  const UpdateVendorEvent({required this.vendorId, required this.payload});

  @override
  List<Object?> get props => [vendorId, payload];
}

/// Delete a vendor
class DeleteVendorEvent extends VendorEvent {
  final int vendorId;

  const DeleteVendorEvent(this.vendorId);

  @override
  List<Object?> get props => [vendorId];
}

/// Toggle login permission for a vendor
class ToggleVendorLoginEvent extends VendorEvent {
  final int vendorId;

  const ToggleVendorLoginEvent(this.vendorId);

  @override
  List<Object?> get props => [vendorId];
}

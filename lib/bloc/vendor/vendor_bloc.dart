import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/vendor_repository.dart';
import 'vendor_event.dart';
import 'vendor_state.dart';

class VendorBloc extends Bloc<VendorEvent, VendorState> {
  final VendorRepository repository;

  VendorBloc({required this.repository}) : super(const VendorInitial()) {
    on<FetchVendorsEvent>(_onFetchVendors);
    on<RefreshVendorsEvent>(_onRefreshVendors);
    on<CreateVendorEvent>(_onCreateVendor);
    on<UpdateVendorEvent>(_onUpdateVendor);
    on<DeleteVendorEvent>(_onDeleteVendor);
    on<ToggleVendorLoginEvent>(_onToggleVendorLogin);
  }

  Future<void> _onFetchVendors(
    FetchVendorsEvent event,
    Emitter<VendorState> emit,
  ) async {
    emit(const VendorLoading());
    try {
      final vendors = await repository.getVendors();
      emit(VendorLoaded(vendors: vendors));
    } catch (e) {
      emit(
        VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onRefreshVendors(
    RefreshVendorsEvent event,
    Emitter<VendorState> emit,
  ) async {
    try {
      final vendors = await repository.getVendors();
      emit(VendorLoaded(vendors: vendors));
    } catch (e) {
      emit(
        VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onCreateVendor(
    CreateVendorEvent event,
    Emitter<VendorState> emit,
  ) async {
    try {
      await repository.createVendor(event.payload);
      final vendors = await repository.getVendors();
      emit(VendorLoaded(vendors: vendors));
    } catch (e) {
      emit(
        VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onUpdateVendor(
    UpdateVendorEvent event,
    Emitter<VendorState> emit,
  ) async {
    try {
      await repository.updateVendor(event.vendorId, event.payload);
      final vendors = await repository.getVendors();
      emit(VendorLoaded(vendors: vendors));
    } catch (e) {
      emit(
        VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onDeleteVendor(
    DeleteVendorEvent event,
    Emitter<VendorState> emit,
  ) async {
    try {
      await repository.deleteVendor(event.vendorId);
      final vendors = await repository.getVendors();
      emit(VendorLoaded(vendors: vendors));
    } catch (e) {
      emit(
        VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onToggleVendorLogin(
    ToggleVendorLoginEvent event,
    Emitter<VendorState> emit,
  ) async {
    if (state is VendorLoaded) {
      final currentList = (state as VendorLoaded).vendors;
      try {
        final updatedVendor = await repository.toggleVendorLogin(
          event.vendorId,
        );
        final updatedList = currentList.map((v) {
          return v.id == updatedVendor.id ? updatedVendor : v;
        }).toList();
        emit(VendorLoaded(vendors: updatedList));
      } catch (e) {
        emit(
          VendorError(errorMessage: e.toString().replaceAll('Exception: ', '')),
        );
      }
    }
  }
}

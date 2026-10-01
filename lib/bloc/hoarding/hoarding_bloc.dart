import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/hoarding_repository.dart';
import '../../models/hoarding_city_model.dart';
import '../../models/hoarding_vendor_model.dart';
import '../../models/hoarding_site_model.dart';
import 'hoarding_event.dart';
import 'hoarding_state.dart';

class HoardingBloc extends Bloc<HoardingEvent, HoardingState> {
  final HoardingRepository repository;

  HoardingBloc({required this.repository}) : super(const HoardingInitial()) {
    on<FetchHoardingDataEvent>(_onFetchHoardingData);
    on<RefreshHoardingDataEvent>(_onRefreshHoardingData);
    on<FilterSitesEvent>(_onFilterSites);
    on<CreateCityEvent>(_onCreateCity);
    on<UpdateCityEvent>(_onUpdateCity);
    on<DeleteCityEvent>(_onDeleteCity);
    on<CreateHoardingVendorEvent>(_onCreateVendor);
    on<UpdateHoardingVendorEvent>(_onUpdateVendor);
    on<DeleteHoardingVendorEvent>(_onDeleteVendor);
    on<CreateSiteEvent>(_onCreateSite);
    on<UpdateSiteEvent>(_onUpdateSite);
    on<DeleteSiteEvent>(_onDeleteSite);
  }

  Future<void> _onFetchHoardingData(
    FetchHoardingDataEvent event,
    Emitter<HoardingState> emit,
  ) async {
    emit(const HoardingLoading());
    try {
      final results = await Future.wait([
        repository.getCities().catchError((_) => <HoardingCityModel>[]),
        repository.getVendors().catchError((_) => <HoardingVendorModel>[]),
        repository.getSites().catchError((_) => <HoardingSiteModel>[]),
      ]);

      emit(HoardingLoaded(
        cities: results[0] as List<HoardingCityModel>,
        vendors: results[1] as List<HoardingVendorModel>,
        sites: results[2] as List<HoardingSiteModel>,
      ));
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshHoardingData(
    RefreshHoardingDataEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      final currentState = state is HoardingLoaded ? (state as HoardingLoaded) : null;
      final results = await Future.wait([
        repository.getCities().catchError((_) => currentState?.cities ?? <HoardingCityModel>[]),
        repository.getVendors().catchError((_) => currentState?.vendors ?? <HoardingVendorModel>[]),
        repository.getSites(
          cityId: currentState?.selectedCityId,
          vendorId: currentState?.selectedVendorId,
          type: currentState?.selectedType,
          status: currentState?.selectedStatus,
        ).catchError((_) => currentState?.sites ?? <HoardingSiteModel>[]),
      ]);

      emit(HoardingLoaded(
        cities: results[0] as List<HoardingCityModel>,
        vendors: results[1] as List<HoardingVendorModel>,
        sites: results[2] as List<HoardingSiteModel>,
        selectedCityId: currentState?.selectedCityId,
        selectedVendorId: currentState?.selectedVendorId,
        selectedType: currentState?.selectedType,
        selectedStatus: currentState?.selectedStatus,
      ));
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFilterSites(
    FilterSitesEvent event,
    Emitter<HoardingState> emit,
  ) async {
    if (state is! HoardingLoaded) return;
    final currentState = state as HoardingLoaded;

    try {
      final sites = await repository.getSites(
        cityId: event.cityId,
        vendorId: event.vendorId,
        type: event.type,
        status: event.status,
      );

      emit(currentState.copyWith(
        sites: sites,
        selectedCityId: event.cityId,
        selectedVendorId: event.vendorId,
        selectedType: event.type,
        selectedStatus: event.status,
      ));
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateCity(
    CreateCityEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.createCity(event.data);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCity(
    UpdateCityEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.updateCity(event.id, event.data);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCity(
    DeleteCityEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.deleteCity(event.id);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateVendor(
    CreateHoardingVendorEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.createVendor(event.data);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateVendor(
    UpdateHoardingVendorEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.updateVendor(event.id, event.data);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteVendor(
    DeleteHoardingVendorEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.deleteVendor(event.id);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSite(
    CreateSiteEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.createSite(event.data, photoFilePath: event.photoPath);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSite(
    UpdateSiteEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.updateSite(event.id, event.data, photoFilePath: event.photoPath);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteSite(
    DeleteSiteEvent event,
    Emitter<HoardingState> emit,
  ) async {
    try {
      await repository.deleteSite(event.id);
      add(const RefreshHoardingDataEvent());
    } catch (e) {
      emit(HoardingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }
}

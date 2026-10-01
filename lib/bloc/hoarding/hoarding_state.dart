import 'package:equatable/equatable.dart';
import '../../models/hoarding_city_model.dart';
import '../../models/hoarding_vendor_model.dart';
import '../../models/hoarding_site_model.dart';

abstract class HoardingState extends Equatable {
  const HoardingState();

  @override
  List<Object?> get props => [];
}

class HoardingInitial extends HoardingState {
  const HoardingInitial();
}

class HoardingLoading extends HoardingState {
  const HoardingLoading();
}

class HoardingLoaded extends HoardingState {
  final List<HoardingCityModel> cities;
  final List<HoardingVendorModel> vendors;
  final List<HoardingSiteModel> sites;
  final int? selectedCityId;
  final int? selectedVendorId;
  final String? selectedType;
  final String? selectedStatus;

  const HoardingLoaded({
    required this.cities,
    required this.vendors,
    required this.sites,
    this.selectedCityId,
    this.selectedVendorId,
    this.selectedType,
    this.selectedStatus,
  });

  int get totalSites => sites.length;
  int get activeSites => sites.where((s) => s.status == 'Active').length;
  int get maintenanceSites => sites.where((s) => s.status == 'Maintenance').length;
  double get totalMonthlyRent => sites.fold(0.0, (acc, s) => acc + s.monthlyRent);

  HoardingLoaded copyWith({
    List<HoardingCityModel>? cities,
    List<HoardingVendorModel>? vendors,
    List<HoardingSiteModel>? sites,
    int? selectedCityId,
    int? selectedVendorId,
    String? selectedType,
    String? selectedStatus,
  }) {
    return HoardingLoaded(
      cities: cities ?? this.cities,
      vendors: vendors ?? this.vendors,
      sites: sites ?? this.sites,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      selectedVendorId: selectedVendorId ?? this.selectedVendorId,
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  @override
  List<Object?> get props => [
        cities,
        vendors,
        sites,
        selectedCityId,
        selectedVendorId,
        selectedType,
        selectedStatus,
      ];
}

class HoardingError extends HoardingState {
  final String errorMessage;

  const HoardingError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

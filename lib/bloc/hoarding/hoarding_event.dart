import 'package:equatable/equatable.dart';

abstract class HoardingEvent extends Equatable {
  const HoardingEvent();

  @override
  List<Object?> get props => [];
}

class FetchHoardingDataEvent extends HoardingEvent {
  const FetchHoardingDataEvent();
}

class RefreshHoardingDataEvent extends HoardingEvent {
  const RefreshHoardingDataEvent();
}

class FilterSitesEvent extends HoardingEvent {
  final int? cityId;
  final int? vendorId;
  final String? type;
  final String? status;

  const FilterSitesEvent({this.cityId, this.vendorId, this.type, this.status});

  @override
  List<Object?> get props => [cityId, vendorId, type, status];
}

class CreateCityEvent extends HoardingEvent {
  final Map<String, dynamic> data;
  const CreateCityEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateCityEvent extends HoardingEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateCityEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteCityEvent extends HoardingEvent {
  final int id;
  const DeleteCityEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateHoardingVendorEvent extends HoardingEvent {
  final Map<String, dynamic> data;
  const CreateHoardingVendorEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateHoardingVendorEvent extends HoardingEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateHoardingVendorEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteHoardingVendorEvent extends HoardingEvent {
  final int id;
  const DeleteHoardingVendorEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateSiteEvent extends HoardingEvent {
  final Map<String, dynamic> data;
  final String? photoPath;
  const CreateSiteEvent(this.data, {this.photoPath});
  @override
  List<Object?> get props => [data, photoPath];
}

class UpdateSiteEvent extends HoardingEvent {
  final int id;
  final Map<String, dynamic> data;
  final String? photoPath;
  const UpdateSiteEvent(this.id, this.data, {this.photoPath});
  @override
  List<Object?> get props => [id, data, photoPath];
}

class DeleteSiteEvent extends HoardingEvent {
  final int id;
  const DeleteSiteEvent(this.id);
  @override
  List<Object?> get props => [id];
}

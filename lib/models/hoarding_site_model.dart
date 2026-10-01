import 'package:equatable/equatable.dart';
import 'hoarding_city_model.dart';
import 'hoarding_vendor_model.dart';
import 'hoarding_site_log_model.dart';

class HoardingSiteModel extends Equatable {
  final int id;
  final String siteCode;
  final String name;
  final int cityId;
  final int hoardingVendorId;
  int get vendorId => hoardingVendorId;
  final String type; // Unipole, Hoarding, Flex
  final String side; // Single Side, Double Side
  final double? width;
  final double? height;
  final double monthlyRent;
  final String status; // Active, Maintenance
  final String? photoPath;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? remarks;
  final HoardingCityModel? city;
  final HoardingVendorModel? vendor;
  final List<HoardingSiteLogModel> logs;
  final DateTime? createdAt;

  const HoardingSiteModel({
    required this.id,
    required this.siteCode,
    required this.name,
    required this.cityId,
    required this.hoardingVendorId,
    this.type = 'Hoarding',
    this.side = 'Single Side',
    this.width,
    this.height,
    this.monthlyRent = 0.0,
    this.status = 'Active',
    this.photoPath,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.remarks,
    this.city,
    this.vendor,
    this.logs = const [],
    this.createdAt,
  });

  factory HoardingSiteModel.fromJson(Map<String, dynamic> json) {
    List<HoardingSiteLogModel> logsList = [];
    if (json['logs'] is List) {
      logsList = (json['logs'] as List)
          .map((e) => HoardingSiteLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return HoardingSiteModel(
      id: json['id'] as int? ?? 0,
      siteCode: json['site_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cityId: json['city_id'] as int? ?? 0,
      hoardingVendorId: json['hoarding_vendor_id'] as int? ?? 0,
      type: json['type'] as String? ?? 'Hoarding',
      side: json['side'] as String? ?? 'Single Side',
      width: json['width'] != null ? double.tryParse(json['width'].toString()) : null,
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,
      monthlyRent: json['monthly_rent'] != null
          ? double.tryParse(json['monthly_rent'].toString()) ?? 0.0
          : 0.0,
      status: json['status'] as String? ?? 'Active',
      photoPath: json['photo_path'] as String?,
      photoUrl: json['photo_url'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      remarks: json['remarks'] as String?,
      city: json['city'] is Map<String, dynamic>
          ? HoardingCityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      vendor: json['vendor'] is Map<String, dynamic>
          ? HoardingVendorModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      logs: logsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_code': siteCode,
      'name': name,
      'city_id': cityId,
      'hoarding_vendor_id': hoardingVendorId,
      'type': type,
      'side': side,
      'width': width,
      'height': height,
      'monthly_rent': monthlyRent,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'remarks': remarks,
    };
  }

  @override
  List<Object?> get props => [
        id,
        siteCode,
        name,
        cityId,
        hoardingVendorId,
        type,
        side,
        monthlyRent,
        status,
        latitude,
        longitude,
        photoUrl,
      ];
}

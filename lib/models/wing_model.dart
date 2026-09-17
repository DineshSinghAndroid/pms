import 'package:equatable/equatable.dart';

class WingModel extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusMeters;
  final DateTime? createdAt;

  const WingModel({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters = 200,
    this.createdAt,
  });

  factory WingModel.fromJson(Map<String, dynamic> json) {
    return WingModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      geofenceRadiusMeters: json['geofence_radius_meters'] as int? ?? 200,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, code, location, latitude, longitude, geofenceRadiusMeters, createdAt];
}

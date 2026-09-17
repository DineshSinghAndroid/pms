import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class UserLocationSyncService {
  static final UserLocationSyncService _instance = UserLocationSyncService._internal();
  factory UserLocationSyncService() => _instance;
  UserLocationSyncService._internal();

  bool _isSyncing = false;

  /// Trigger live GPS acquisition and send coordinates to backend
  Future<bool> syncCurrentLocation({String source = 'app_active'}) async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [LocationSync] Location services disabled on device.');
        _isSyncing = false;
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [LocationSync] Location permission denied ($permission).');
        _isSyncing = false;
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final ok = await ApiService().updateUserLocation(
        position.latitude,
        position.longitude,
        source: source,
      );

      debugPrint('📍 [LocationSync] Location synced (${position.latitude}, ${position.longitude}) -> success: $ok');
      _isSyncing = false;
      return ok;
    } catch (e) {
      debugPrint('⚠️ [LocationSync] Error acquiring or syncing location: $e');
      _isSyncing = false;
      return false;
    }
  }
}

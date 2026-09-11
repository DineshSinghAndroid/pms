import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType { camera, gallery, location }

class AppPermissionStatus {
  final AppPermissionType type;
  final String title;
  final String description;
  final bool isGranted;
  final bool isPermanentlyDenied;

  const AppPermissionStatus({
    required this.type,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isPermanentlyDenied,
  });
}

class PermissionService {
  static const List<AppPermissionType> mandatoryPermissions = [
    AppPermissionType.camera,
    AppPermissionType.gallery,
    AppPermissionType.location,
  ];

  static bool _isUsable(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static bool _isBlocked(PermissionStatus status) =>
      status.isPermanentlyDenied || status.isRestricted;

  /// Check all mandatory permissions
  static Future<List<AppPermissionStatus>> checkAllPermissions() async {
    if (kIsWeb) {
      // On web, permissions are handled on-demand by the browser
      return [
        const AppPermissionStatus(
          type: AppPermissionType.camera,
          title: 'Camera',
          description: 'Capture live proof photos and artwork samples.',
          isGranted: true,
          isPermanentlyDenied: false,
        ),
        const AppPermissionStatus(
          type: AppPermissionType.gallery,
          title: 'Photos & Media Gallery',
          description: 'Select artwork, PDF proofs, and media attachments.',
          isGranted: true,
          isPermanentlyDenied: false,
        ),
        const AppPermissionStatus(
          type: AppPermissionType.location,
          title: 'Location',
          description: 'Required for campus job dispatch and attendance.',
          isGranted: true,
          isPermanentlyDenied: false,
        ),
      ];
    }

    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    final photosStatus = await _galleryStatus();

    return [
      AppPermissionStatus(
        type: AppPermissionType.camera,
        title: 'Camera',
        description:
            'Required for taking live proof photos and artwork samples.',
        isGranted: _isUsable(cameraStatus),
        isPermanentlyDenied: _isBlocked(cameraStatus),
      ),
      AppPermissionStatus(
        type: AppPermissionType.gallery,
        title: 'Photos & Media Gallery',
        description:
            'Required for attaching designs, PDFs, videos, and specifications.',
        isGranted: _isUsable(photosStatus),
        isPermanentlyDenied: _isBlocked(photosStatus),
      ),
      AppPermissionStatus(
        type: AppPermissionType.location,
        title: 'Location',
        description:
            'Required for campus job dispatch, verification, and attendance.',
        isGranted: _isUsable(locationStatus),
        isPermanentlyDenied: _isBlocked(locationStatus),
      ),
    ];
  }

  static Future<PermissionStatus> _galleryStatus() async {
    var photosStatus = await Permission.photos.status;
    // Android legacy storage fallback (API <= 32). Not used on iOS.
    if (!_isUsable(photosStatus) && !kIsWeb && Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (_isUsable(storageStatus)) {
        return storageStatus;
      }
    }
    return photosStatus;
  }

  /// Are all mandatory permissions granted?
  static Future<bool> areAllPermissionsGranted() async {
    if (kIsWeb) return true;
    final statuses = await checkAllPermissions();
    return statuses.every((p) => p.isGranted);
  }

  /// Request mandatory permissions sequentially one-by-one
  static Future<List<AppPermissionStatus>>
  requestAllPermissionsOneByOne() async {
    if (kIsWeb) return checkAllPermissions();

    await _requestIfNeeded(Permission.camera);
    await _requestGalleryIfNeeded();
    await _requestIfNeeded(Permission.locationWhenInUse);

    return checkAllPermissions();
  }

  static Future<void> _requestIfNeeded(Permission permission) async {
    final status = await permission.status;
    if (_isUsable(status)) return;

    // Permanently denied / restricted: system will not show a popup again.
    if (_isBlocked(status)) return;

    await permission.request();
  }

  static Future<void> _requestGalleryIfNeeded() async {
    final photoStatus = await Permission.photos.status;
    if (_isUsable(photoStatus)) return;

    if (!_isBlocked(photoStatus)) {
      final res = await Permission.photos.request();
      if (_isUsable(res)) return;
    }

    // Android only: older storage permission
    if (!kIsWeb && Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (!_isUsable(storageStatus) && !_isBlocked(storageStatus)) {
        await Permission.storage.request();
      }
    }
  }

  /// Open device app settings
  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType {
  camera,
  gallery,
  location,
}

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

    // Photos / Storage check
    var photosStatus = await Permission.photos.status;
    if (!photosStatus.isGranted) {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        photosStatus = storageStatus;
      }
    }

    return [
      AppPermissionStatus(
        type: AppPermissionType.camera,
        title: 'Camera',
        description: 'Required for taking live proof photos and artwork samples.',
        isGranted: cameraStatus.isGranted || cameraStatus.isLimited,
        isPermanentlyDenied: cameraStatus.isPermanentlyDenied || cameraStatus.isRestricted,
      ),
      AppPermissionStatus(
        type: AppPermissionType.gallery,
        title: 'Photos & Media Gallery',
        description: 'Required for attaching designs, PDFs, videos, and specifications.',
        isGranted: photosStatus.isGranted || photosStatus.isLimited,
        isPermanentlyDenied: photosStatus.isPermanentlyDenied || photosStatus.isRestricted,
      ),
      AppPermissionStatus(
        type: AppPermissionType.location,
        title: 'Location',
        description: 'Required for campus job dispatch, verification, and attendance.',
        isGranted: locationStatus.isGranted || locationStatus.isLimited,
        isPermanentlyDenied: locationStatus.isPermanentlyDenied || locationStatus.isRestricted,
      ),
    ];
  }

  /// Are all mandatory permissions granted?
  static Future<bool> areAllPermissionsGranted() async {
    if (kIsWeb) return true;
    final statuses = await checkAllPermissions();
    return statuses.every((p) => p.isGranted);
  }

  /// Request mandatory permissions sequentially one-by-one
  static Future<List<AppPermissionStatus>> requestAllPermissionsOneByOne() async {
    if (kIsWeb) return checkAllPermissions();

    // 1. Camera
    final camStatus = await Permission.camera.status;
    if (!camStatus.isGranted && !camStatus.isLimited) {
      await Permission.camera.request();
    }

    // 2. Photos / Storage
    final photoStatus = await Permission.photos.status;
    if (!photoStatus.isGranted && !photoStatus.isLimited) {
      final res = await Permission.photos.request();
      if (!res.isGranted) {
        await Permission.storage.request();
      }
    }

    // 3. Location
    final locStatus = await Permission.locationWhenInUse.status;
    if (!locStatus.isGranted && !locStatus.isLimited) {
      await Permission.locationWhenInUse.request();
    }

    return checkAllPermissions();
  }

  /// Open device app settings
  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}

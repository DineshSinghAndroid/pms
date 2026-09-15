import 'dart:io';

class AppUpdateInfo {
  final int latestBuildNumber;
  final bool isForceUpdate;
  final String playStoreUrl;
  final String appStoreUrl;
  final String title;
  final String message;
  final String? updatedAt;

  const AppUpdateInfo({
    required this.latestBuildNumber,
    required this.isForceUpdate,
    required this.playStoreUrl,
    required this.appStoreUrl,
    required this.title,
    required this.message,
    this.updatedAt,
  });

  /// Check whether an update is available based ONLY on the build number
  bool isUpdateAvailable(int currentBuildNumber) {
    return latestBuildNumber > currentBuildNumber;
  }

  /// Get device-specific store URL
  String getPlatformUrl() {
    try {
      if (Platform.isAndroid) {
        if (playStoreUrl.trim().isNotEmpty) return playStoreUrl.trim();
        return 'https://play.google.com/store/apps/details?id=com.pms.prince.pms';
      } else if (Platform.isIOS) {
        if (appStoreUrl.trim().isNotEmpty) return appStoreUrl.trim();
        if (playStoreUrl.trim().isNotEmpty) return playStoreUrl.trim();
        return 'https://apps.apple.com/app/com.pms.prince.pms';
      }
    } catch (_) {
      // Platform detection fallback (e.g. web/test)
    }

    if (playStoreUrl.trim().isNotEmpty) return playStoreUrl.trim();
    if (appStoreUrl.trim().isNotEmpty) return appStoreUrl.trim();
    return 'https://play.google.com/store/apps/details?id=com.pms.prince.pms';
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestBuildNumber: (json['latest_build_number'] as num?)?.toInt() ?? 4,
      isForceUpdate: json['is_force_update'] == true ||
          json['is_force_update'] == 1 ||
          json['is_force_update'] == '1',
      playStoreUrl: json['play_store_url']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.pms.prince.pms',
      appStoreUrl: json['app_store_url']?.toString() ??
          'https://apps.apple.com/app/com.pms.prince.pms',
      title: json['title']?.toString() ?? 'New Update Available',
      message: json['message']?.toString() ??
          'A new version of PMS Admin is available. Please update to continue.',
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_build_number': latestBuildNumber,
      'is_force_update': isForceUpdate,
      'play_store_url': playStoreUrl,
      'app_store_url': appStoreUrl,
      'title': title,
      'message': message,
      'updated_at': updatedAt,
    };
  }
}

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../views/purchase_requests/pr_details_screen.dart';
import 'api_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🌙 [FCM Background] Message received: ${message.messageId}");
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Android channel with custom sound 'plop' (maps to res/raw/plop.mp3)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pms_pr_channel_v2',
    'Purchase Request Notifications',
    description: 'High priority alerts for new Wing Incharge PR requests',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('plop'),
    playSound: true,
    enableVibration: true,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserPhone;
  String? _currentToken;
  bool _isInitialized = false;
  VoidCallback? onNotificationReceived;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Initialize Firebase Messaging handlers and listeners
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    if (_isInitialized) return;
    _navigatorKey = navKey;
    _isInitialized = true;

    try {
      // 1. Request FCM notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 2. Set presentation options for foreground on iOS (Alert + Sound + Badge)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Flutter Local Notifications for Android/iOS
      await _initializeLocalNotifications();

      // 4. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 [FCM] Token refreshed: $newToken');
        _currentToken = newToken;
        if (_currentUserPhone != null) {
          _sendTokenToBackend(newToken, _currentUserPhone!);
        }
      });

      // 6. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('☀️ [FCM Foreground] Received: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 7. Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [FCM Open] App opened from notification: ${message.data}');
        _handleNotificationClick(message.data);
      });

      // 8. Check if app was opened from terminated state via notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🏁 [FCM Initial] App launched from notification: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleNotificationClick(initialMessage.data);
        });
      }

      // 9. Fetch current token in background (non-blocking for app startup)
      _fetchInitialTokenAsync();
    } catch (e) {
      debugPrint('⚠️ [FCM Init Error]: $e');
    }
  }

  void _fetchInitialTokenAsync() async {
    try {
      final token = await _getFcmTokenWithRetry();
      if (token != null) {
        _currentToken = token;
        debugPrint('🔑 [FCM Token Ready]: $_currentToken');
        if (_currentUserPhone != null) {
          await _sendTokenToBackend(token, _currentUserPhone!);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FCM Async Token Error]: $e');
    }
  }

  /// Safely obtain FCM token, waiting for APNs device token on iOS physical devices
  Future<String?> _getFcmTokenWithRetry() async {
    if (kIsWeb) {
      return await _fcm.getToken();
    }

    if (Platform.isIOS) {
      // On iOS devices, Firebase requires the APNs device token from Apple first
      String? apnsToken = await _fcm.getAPNSToken();
      int retries = 0;
      while (apnsToken == null && retries < 15) {
        debugPrint('⏳ [FCM iOS] Waiting for APNs token from Apple (attempt ${retries + 1}/15)...');
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await _fcm.getAPNSToken();
        retries++;
      }
      if (apnsToken != null) {
        debugPrint('🍏 [FCM iOS] APNs token: READY (${apnsToken.substring(0, 10)}...)');
      } else {
        debugPrint('⚠️ [FCM iOS] APNs token NOT available after 15s (expected on iOS Simulator, required on physical device)');
      }
    }

    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('⚠️ [FCM getToken error]: $e');
      return null;
    }
  }

  /// Initialize local notifications plugin and create high-importance sound channel on Android
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationClick(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create custom sound channel on Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }
  }

  /// Register device FCM token with backend
  Future<void> registerToken(String phone) async {
    _currentUserPhone = phone;
    debugPrint('📱 [FCM] Requesting token registration for phone: $phone...');
    try {
      final token = _currentToken ?? await _getFcmTokenWithRetry();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _sendTokenToBackend(token, phone);
      } else {
        debugPrint('⚠️ [FCM] Token not available yet for $phone. Scheduling retry in 3 seconds...');
        Future.delayed(const Duration(seconds: 3), () {
          if (_currentUserPhone == phone) {
            registerToken(phone);
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ [FCM Register Error]: $e');
    }
  }

  /// Send device token to PMS Admin backend
  Future<void> _sendTokenToBackend(String token, String phone) async {
    try {
      String deviceType = 'android';
      if (kIsWeb) {
        deviceType = 'web';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      }

      final res = await _apiService.client.post('/api/fcm-token', data: {
        'fcm_token': token,
        'phone': phone,
        'device_type': deviceType,
      });

      debugPrint('✅ [FCM Registered with Backend]: ${res.data}');
    } catch (e) {
      debugPrint('❌ [FCM Register Failed]: $e');
    }
  }

  /// Display notification in foreground with sound
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? '';
    final data = message.data;

    try {
      onNotificationReceived?.call();
    } catch (_) {}

    // 1. Show local heads-up notification with custom sound
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('plop'),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'plop.caf',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }

    // 2. Also display floating interactive in-app snackbar
    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;

    final prIdStr = data['pr_id']?.toString();
    final prId = prIdStr != null ? int.tryParse(prIdStr) : null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFF60A5FA), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        action: prId != null
            ? SnackBarAction(
                label: 'VIEW PR',
                textColor: const Color(0xFF60A5FA),
                onPressed: () {
                  _navigateToPR(prId);
                },
              )
            : null,
      ),
    );
  }

  /// Handle navigation on notification tap
  void _handleNotificationClick(Map<String, dynamic> data) {
    final prIdStr = data['pr_id']?.toString();
    if (prIdStr != null) {
      final prId = int.tryParse(prIdStr);
      if (prId != null) {
        _navigateToPR(prId);
      }
    }
  }

  void _navigateToPR(int prId) {
    final navState = _navigatorKey?.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => PRDetailsScreen(
            prId: prId,
            isSuperAdmin: true,
          ),
        ),
      );
    }
  }
}

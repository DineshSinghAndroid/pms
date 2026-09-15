import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../views/purchase_requests/pr_details_screen.dart';
import 'api_service.dart';
import '../theme/pms_theme.dart';

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
  OverlayEntry? _currentTopBanner;
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

    // 2. Display interactive top-bar notification banner (no bottom popup)
    _showTopBarNotificationBanner(
      title: title,
      body: body,
      data: data,
    );
  }

  /// Display heads-up top bar banner overlay
  void _showTopBarNotificationBanner({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navState = _navigatorKey?.currentState;
      final overlay = navState?.overlay;
      if (overlay == null) return;

      _dismissCurrentBanner();

      final prIdStr = data['pr_id']?.toString();
      final prId = prIdStr != null ? int.tryParse(prIdStr) : null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => _TopNotificationBannerWidget(
          title: title,
          body: body,
          prId: prId,
          onDismiss: () {
            if (_currentTopBanner == entry) {
              try {
                entry.remove();
              } catch (_) {}
              _currentTopBanner = null;
            }
          },
          onTap: () {
            if (_currentTopBanner == entry) {
              try {
                entry.remove();
              } catch (_) {}
              _currentTopBanner = null;
            }
            if (prId != null) {
              _navigateToPR(prId);
            } else {
              _handleNotificationClick(data);
            }
          },
        ),
      );

      _currentTopBanner = entry;
      overlay.insert(entry);
    });
  }

  void _dismissCurrentBanner() {
    try {
      _currentTopBanner?.remove();
    } catch (_) {}
    _currentTopBanner = null;
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

/// Interactive heads-up notification banner that slides down from the top bar
class _TopNotificationBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final int? prId;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _TopNotificationBannerWidget({
    required this.title,
    required this.body,
    this.prId,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_TopNotificationBannerWidget> createState() =>
      _TopNotificationBannerWidgetState();
}

class _TopNotificationBannerWidgetState
    extends State<_TopNotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _animController.forward();

    // Auto dismiss after 5.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 5500), () {
      _closeBanner();
    });
  }

  void _closeBanner() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: topPadding > 0 ? topPadding + 4 : 12,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {
              _dismissTimer?.cancel();
              _animController.reverse().then((_) {
                widget.onTap();
              });
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -3) {
                _closeBanner();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: PmsTheme.textPrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF38BDF8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              style: const TextStyle(
                                color: PmsTheme.textMuted,
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.prId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VIEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                      onPressed: _closeBanner,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

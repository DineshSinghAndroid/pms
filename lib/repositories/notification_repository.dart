import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  /// Fetch user notifications and unread counter
  Future<NotificationFetchResult> getNotifications(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final res = await _apiService.client.get(
        '/api/notifications',
        queryParameters: {'phone': cleanPhone},
      );

      if (res.data != null && res.data['success'] == true) {
        final List rawList = res.data['data'] as List? ?? [];
        final notifications = rawList.map((e) => PmsNotificationItem.fromJson(e)).toList();
        final unreadCount = res.data['unread_count'] is int
            ? res.data['unread_count'] as int
            : int.tryParse(res.data['unread_count']?.toString() ?? '0') ?? 0;

        return NotificationFetchResult(
          notifications: notifications,
          unreadCount: unreadCount,
        );
      }
      return NotificationFetchResult(notifications: [], unreadCount: 0);
    } catch (e) {
      return NotificationFetchResult(notifications: [], unreadCount: 0);
    }
  }

  /// Mark single notification as read
  Future<bool> markAsRead(int id, String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final res = await _apiService.client.post('/api/notifications/mark-read', data: {
        'id': id,
        'phone': cleanPhone,
      });
      return res.data?['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final res = await _apiService.client.post('/api/notifications/mark-read', data: {
        'phone': cleanPhone,
      });
      return res.data?['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

class NotificationFetchResult {
  final List<PmsNotificationItem> notifications;
  final int unreadCount;

  NotificationFetchResult({
    required this.notifications,
    required this.unreadCount,
  });
}

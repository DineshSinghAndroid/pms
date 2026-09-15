import 'package:flutter/material.dart';
import '../theme/pms_theme.dart';

class PmsNotificationItem {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime createdAt;

  PmsNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory PmsNotificationItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedData = {};
    if (json['data'] is Map) {
      parsedData = Map<String, dynamic>.from(json['data']);
    }

    return PmsNotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: parsedData,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'purchase_request':
      case 'pr':
        return Icons.shopping_bag_outlined;
      case 'print_order':
      case 'po':
        return Icons.print_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'studio_request':
      case 'digital_studio':
        return Icons.videocam_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get color {
    switch (type.toLowerCase()) {
      case 'purchase_request':
      case 'pr':
        return PmsTheme.primary; // Blue
      case 'print_order':
      case 'po':
        return PmsTheme.primary; // Indigo
      case 'delivery':
        return const Color(0xFF0891B2); // Cyan
      case 'payment':
        return const Color(0xFF059669); // Emerald Green
      case 'studio_request':
      case 'digital_studio':
        return PmsTheme.secondary; // Purple
      case 'announcement':
        return const Color(0xFFD97706); // Amber
      default:
        return PmsTheme.textSecondary; // Slate
    }
  }
}

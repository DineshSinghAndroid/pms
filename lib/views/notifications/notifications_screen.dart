import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/app_gradient_background.dart';
import '../purchase_requests/pr_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userPhone;
  final bool isSuperAdmin;

  const NotificationsScreen({
    super.key,
    required this.userPhone,
    this.isSuperAdmin = false,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository();

  bool _isLoading = true;
  List<PmsNotificationItem> _notifications = [];
  int _unreadCount = 0;
  String _filter = 'all'; // 'all' or 'unread'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final result = await _repository.getNotifications(widget.userPhone);
    if (mounted) {
      setState(() {
        _notifications = result.notifications;
        _unreadCount = result.unreadCount;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    final prevUnread = _unreadCount;
    setState(() {
      _unreadCount = 0;
      for (var item in _notifications) {
        item.isRead = true;
      }
    });

    final success = await _repository.markAllAsRead(widget.userPhone);
    if (!success && mounted) {
      setState(() => _unreadCount = prevUnread);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark all as read. Check network.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(PmsNotificationItem item) async {
    // 1. Mark as read locally and on server
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
        if (_unreadCount > 0) _unreadCount--;
      });
      _repository.markAsRead(item.id, widget.userPhone);
    }

    // 2. Extract deep-link data
    final data = item.data;
    final prIdStr = data['pr_id']?.toString();
    final prId = prIdStr != null ? int.tryParse(prIdStr) : null;

    if (prId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PRDetailsScreen(
            prId: prId,
            isSuperAdmin: widget.isSuperAdmin,
          ),
        ),
      );
      return;
    }

    // 3. Otherwise show details sheet
    _showNotificationDetailsSheet(item);
  }

  void _showNotificationDetailsSheet(PmsNotificationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PmsTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: PmsTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: PmsTheme.glassBorder),
                const SizedBox(height: 12),
                Text(
                  item.body.isNotEmpty ? item.body : 'No additional details.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PmsNotificationItem> get _filteredList {
    if (_filter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: PmsTheme.glassSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PmsTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context, _unreadCount),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PmsTheme.textPrimary,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: PmsTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: PmsTheme.primary),
              label: const Text(
                'Mark read',
                style: TextStyle(
                  color: PmsTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Unread)
          Container(
            color: PmsTheme.glassSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All (${_notifications.length})', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Unread ($_unreadCount)', 'unread'),
              ],
            ),
          ),
          const Divider(height: 1, color: PmsTheme.glassBorder),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: PmsTheme.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: PmsTheme.primary,
                    child: _filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: _filteredList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _filteredList[index];
                              return _buildNotificationCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? PmsTheme.primary.withValues(alpha: 0.14) : PmsTheme.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? PmsTheme.glassBorderActive : PmsTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? PmsTheme.primary : PmsTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(PmsNotificationItem item) {
    return Material(
      color: item.isRead ? Colors.white : PmsTheme.backgroundGradientStart,
      borderRadius: BorderRadius.circular(14),
      elevation: item.isRead ? 0.5 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleNotificationTap(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? PmsTheme.glassBorder : const Color(0xFFBFDBFE),
              width: item.isRead ? 0.8 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: PmsTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isRead ? PmsTheme.textMuted : PmsTheme.primary,
                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isRead ? PmsTheme.textSecondary : const Color(0xFF334155),
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Unread Blue Dot
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: PmsTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: PmsTheme.bgSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: PmsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'unread' ? 'No Unread Notifications' : 'No Notifications Yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter == 'unread'
                  ? 'All caught up! Any new alerts will appear here.'
                  : 'You will receive notifications here for PRs, Orders, and Deliveries.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: PmsTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

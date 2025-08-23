import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_text_styles.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/layouts/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _salesEnabled = true;
  bool _messageEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _emailEnabled = prefs.getBool('notif_email') ?? false;
      _salesEnabled = prefs.getBool('notif_sales') ?? true;
      _messageEnabled = prefs.getBool('notif_message') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Welcome to KitaKita!',
      message:
          'Start buying and selling with fellow students. Complete your profile to get started.',
      type: NotificationType.system,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final content = _notifications.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: EdgeInsets.all(
              ResponsiveUtils.isMobile(context)
                  ? AppSizes.paddingM
                  : AppSizes.paddingL,
            ),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationItem(notification, index);
            },
          );

    return MainLayout(
      currentIndex: -1, // Not a main navigation item
      title: unreadCount > 0 
          ? 'Notifications ($unreadCount unread)'
          : 'Notifications',
      actions: [
        if (unreadCount > 0)
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showNotificationSettings,
        ),
      ],
      child: content,
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.white
            : AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.borderGray.withValues(alpha: 0.3)
              : AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSizes.paddingL),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: AppColors.white),
        ),
        onDismissed: (direction) {
          setState(() {
            _notifications.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  setState(() {
                    _notifications.insert(index, notification);
                  });
                },
              ),
            ),
          );
        },
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getNotificationColor(
                notification.type,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: notification.isRead
                        ? AppColors.primaryBlue
                        : AppColors.primaryBlue,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(notification.timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          onTap: () => _onNotificationTap(notification),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Text(
            'No notifications yet',
            style: AppTextStyles.h3.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            'We\'ll notify you about important updates',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.sale:
        return Icons.sell;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.priceAlert:
        return Icons.trending_down;
      case NotificationType.interest:
        return Icons.favorite;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.sale:
        return AppColors.success;
      case NotificationType.message:
        return AppColors.primaryBlue;
      case NotificationType.priceAlert:
        return AppColors.primaryYellow;
      case NotificationType.interest:
        return AppColors.error;
      case NotificationType.system:
        return AppColors.textGray;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _onNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening chat...')));
        break;
      case NotificationType.sale:
      case NotificationType.interest:
        // Navigate to product or sales page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening product details...')),
        );
        break;
      case NotificationType.priceAlert:
        // Navigate to product
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening product with new price...')),
        );
        break;
      case NotificationType.system:
        // Handle system notifications
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSizes.spaceL),

            _buildSettingTile(
              'Push Notifications',
              'Receive notifications on your device',
              _pushEnabled,
              (value) {
                setState(() => _pushEnabled = value);
                _saveSetting('notif_push', value);
              },
            ),

            _buildSettingTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailEnabled,
              (value) {
                setState(() => _emailEnabled = value);
                _saveSetting('notif_email', value);
              },
            ),

            _buildSettingTile(
              'Sales Notifications',
              'Get notified when your items sell',
              _salesEnabled,
              (value) {
                setState(() => _salesEnabled = value);
                _saveSetting('notif_sales', value);
              },
            ),

            _buildSettingTile(
              'Message Notifications',
              'Get notified of new messages',
              _messageEnabled,
              (value) {
                setState(() => _messageEnabled = value);
                _saveSetting('notif_message', value);
              },
            ),

            const SizedBox(height: AppSizes.spaceL),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }
}

// Models
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}

enum NotificationType { sale, message, priceAlert, interest, system }

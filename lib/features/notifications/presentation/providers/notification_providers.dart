import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/models/notification_models.dart';

final _logger = Logger();

// Notification state model
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Notification state notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await SupabaseService.from('notifications')
          .select('''
            id,
            user_id,
            title,
            message,
            type,
            is_read,
            data,
            created_at
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List).map((data) {
        return AppNotification(
          id: data['id'],
          userId: data['user_id'],
          title: data['title'],
          message: data['message'],
          type: _parseNotificationType(data['type']),
          isRead: data['is_read'] ?? false,
          data: data['data'] as Map<String, dynamic>? ?? {},
          createdAt: DateTime.parse(data['created_at']),
        );
      }).toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to load notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.from(
        'notifications',
      ).update({'is_read': true}).eq('id', notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      _logger.e('Failed to mark notification as read: $e');
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await SupabaseService.from(
        'notifications',
      ).update({'is_read': true}).eq('user_id', userId).eq('is_read', false);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      _logger.e('Failed to mark all notifications as read: $e');
      state = state.copyWith(
        error: 'Failed to mark all notifications as read: $e',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseService.from(
        'notifications',
      ).delete().eq('id', notificationId);

      // Update local state
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      _logger.e('Failed to delete notification: $e');
      state = state.copyWith(error: 'Failed to delete notification: $e');
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'is_read': false,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload notifications
      await loadNotifications(userId);
    } catch (e) {
      _logger.e('Failed to create notification: $e');
      state = state.copyWith(error: 'Failed to create notification: $e');
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'product':
        return NotificationType.product;
      case 'system':
        return NotificationType.system;
      case 'verification':
        return NotificationType.verification;
      default:
        return NotificationType.system;
    }
  }
}

// Providers
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier();
    });

// Auto-load notifications when user changes
final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final notificationNotifier = ref.read(notificationProvider.notifier);
  await notificationNotifier.loadNotifications(user.id);
  return ref.read(notificationProvider).notifications;
});

// Unread count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

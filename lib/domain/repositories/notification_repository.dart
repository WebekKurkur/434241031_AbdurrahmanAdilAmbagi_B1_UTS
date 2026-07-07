// lib/domain/repositories/notification_repository.dart

import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Fetch the most recent [limit] notifications for the current
  /// user (newest first).
  Future<List<NotificationEntity>> getNotifications({int limit = 50});

  /// Count of unread notifications for the current user. Used by
  /// the bell badge on the home shell.
  Future<int> getUnreadCount();

  /// Mark a single notification as read. RLS ensures only the
  /// recipient can do this.
  Future<void> markAsRead(String notificationId);

  /// Mark every currently-unread notification for the current
  /// user as read. Used when the bell panel is opened.
  Future<void> markAllAsRead();

  /// Realtime stream of the current user's notifications. Emits
  /// the current list on subscribe AND on every change.
  Stream<List<NotificationEntity>> watchNotifications();
}
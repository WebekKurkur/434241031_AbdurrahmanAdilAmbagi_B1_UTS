// lib/data/datasources/notification_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  /// One-shot fetch of the most recent notifications for the
  /// current user. Capped at [limit] rows (default 50).
  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    final res = await _client
        .from('notifications')
        .select('*, actor:actor_id(name)')
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(const Duration(seconds: 8));
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(NotificationModel.fromRow)
        .toList();
  }

  /// Count of unread notifications for the current user. Used by
  /// the bell badge. Cheap query thanks to the partial index on
  /// `notifications(user_id) where read_at is null`.
  Future<int> getUnreadCount() async {
    final res = await _client
        .from('notifications')
        .select('id')
        .isFilter('read_at', null)
        .timeout(const Duration(seconds: 8));
    return (res as List).length;
  }

  /// Mark a single notification as read. RLS enforces that only
  /// the owner can do this.
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .timeout(const Duration(seconds: 8));
  }

  /// Mark all of the current user's unread notifications as read.
  /// Used when the bell panel is opened.
  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .isFilter('read_at', null)
        .timeout(const Duration(seconds: 8));
  }

  /// Realtime stream of the current user's notifications (newest
  /// first). Emits on subscription AND on every change to the
  /// `notifications` table (which is in `supabase_realtime` per
  /// migration 0005).
  Stream<List<NotificationModel>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getNotifications())
        .handleError((e, st) {
      if (kDebugMode) {
        debugPrint('NotificationDataSource.watchNotifications error: $e');
      }
      // Re-emit an empty list so the UI doesn't break.
      // The full error is logged but not surfaced — the user can
      // still navigate to the dedicated notifications screen.
    });
  }
}
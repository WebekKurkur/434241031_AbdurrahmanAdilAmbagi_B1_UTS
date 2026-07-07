// lib/presentation/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/notification/get_notifications_usecase.dart';
import '../../domain/usecases/notification/mark_notification_read_usecase.dart';
import 'auth_provider.dart';

// Data Sources
final notificationDataSourceProvider =
    Provider((ref) => NotificationDataSource());

// Repositories
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(notificationDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});

// Use Cases
final getNotificationsUseCaseProvider = Provider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return GetNotificationsUseCase(repo);
});

final markNotificationReadUseCaseProvider = Provider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return MarkNotificationReadUseCase(repo);
});

final markAllNotificationsReadUseCaseProvider = Provider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return MarkAllNotificationsReadUseCase(repo);
});

/// Auth-aware realtime stream of the current user's notifications.
/// Depends on `currentUserProvider` so it auto-disposes on logout.
final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    // Logged out → no notifications. Emit empty list immediately
    // so the bell badge doesn't show "loading".
    return const Stream<List<NotificationEntity>>.empty();
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

/// Unread count for the bell badge. Cheap query (partial index
/// on `notifications(user_id) where read_at is null`). Refreshed
/// manually when the user reads a notification.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});
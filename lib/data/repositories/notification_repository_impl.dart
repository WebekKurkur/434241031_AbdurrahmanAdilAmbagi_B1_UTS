// lib/data/repositories/notification_repository_impl.dart

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource dataSource;
  NotificationRepositoryImpl(this.dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications({int limit = 50}) async {
    final models = await dataSource.getNotifications(limit: limit);
    return models.cast<NotificationEntity>();
  }

  @override
  Future<int> getUnreadCount() => dataSource.getUnreadCount();

  @override
  Future<void> markAsRead(String notificationId) =>
      dataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead() => dataSource.markAllAsRead();

  @override
  Stream<List<NotificationEntity>> watchNotifications() {
    return dataSource.watchNotifications();
  }
}
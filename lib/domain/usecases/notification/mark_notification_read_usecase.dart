// lib/domain/usecases/notification/mark_notification_read_usecase.dart

import '../../repositories/notification_repository.dart';
import '../../../core/usecases/usecase.dart';

class MarkNotificationReadParams {
  final String notificationId;
  const MarkNotificationReadParams({required this.notificationId});
}

class MarkNotificationReadUseCase
    implements UseCase<void, MarkNotificationReadParams> {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);

  @override
  Future<void> call(MarkNotificationReadParams params) {
    return repository.markAsRead(params.notificationId);
  }
}

class MarkAllNotificationsReadUseCase extends NoParamsUseCase<void> {
  final NotificationRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);

  @override
  Future<void> call() {
    return repository.markAllAsRead();
  }
}
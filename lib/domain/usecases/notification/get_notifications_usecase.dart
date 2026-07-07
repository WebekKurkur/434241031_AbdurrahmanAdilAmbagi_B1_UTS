// lib/domain/usecases/notification/get_notifications_usecase.dart

import '../../entities/notification_entity.dart';
import '../../repositories/notification_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetNotificationsUseCase extends NoParamsUseCase<List<NotificationEntity>> {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);

  @override
  Future<List<NotificationEntity>> call() {
    return repository.getNotifications();
  }
}
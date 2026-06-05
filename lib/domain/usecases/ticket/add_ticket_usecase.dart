// lib/domain/usecases/ticket/add_ticket_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';
import '../../../core/usecases/usecase.dart';

class AddTicketUseCase implements UseCase<TicketEntity, TicketEntity> {
  final TicketRepository repository;

  AddTicketUseCase(this.repository);

  @override
  Future<TicketEntity> call(TicketEntity params) async {
    return await repository.addTicket(params);
  }
}

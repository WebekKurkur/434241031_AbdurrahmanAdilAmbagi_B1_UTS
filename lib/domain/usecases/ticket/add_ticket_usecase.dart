// lib/domain/usecases/ticket/add_ticket_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';

class AddTicketUseCase {
  final TicketRepository repository;

  AddTicketUseCase(this.repository);

  Future<void> call(TicketEntity ticket) async {
    return await repository.addTicket(ticket);
  }
}

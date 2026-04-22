// lib/domain/usecases/ticket/assign_ticket_usecase.dart

import '../../repositories/ticket_repository.dart';

class AssignTicketUseCase {
  final TicketRepository repository;

  AssignTicketUseCase(this.repository);

  Future<void> call(String ticketId, String assignedTo) async {
    return await repository.assignTicket(ticketId, assignedTo);
  }
}

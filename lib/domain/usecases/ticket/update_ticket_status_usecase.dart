// lib/domain/usecases/ticket/update_ticket_status_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';

class UpdateTicketStatusUseCase {
  final TicketRepository repository;

  UpdateTicketStatusUseCase(this.repository);

  Future<void> call(String ticketId, TicketStatus status) async {
    return await repository.updateTicketStatus(ticketId, status);
  }
}

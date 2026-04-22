// lib/domain/usecases/ticket/get_tickets_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';

class GetTicketsUseCase {
  final TicketRepository repository;

  GetTicketsUseCase(this.repository);

  Future<List<TicketEntity>> call() async {
    return await repository.getTickets();
  }
}

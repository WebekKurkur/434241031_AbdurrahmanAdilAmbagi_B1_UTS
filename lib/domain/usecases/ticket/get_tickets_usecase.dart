// lib/domain/usecases/ticket/get_tickets_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';
import '../../../core/usecases/usecase.dart';

class GetTicketsUseCase implements NoParamsUseCase<List<TicketEntity>> {
  final TicketRepository repository;

  GetTicketsUseCase(this.repository);

  @override
  Future<List<TicketEntity>> call() async {
    return await repository.getTickets();
  }
}

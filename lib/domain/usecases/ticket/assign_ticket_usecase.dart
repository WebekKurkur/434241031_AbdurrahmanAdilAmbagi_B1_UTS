// lib/domain/usecases/ticket/assign_ticket_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../../core/usecases/usecase.dart';

class AssignTicketParams {
  final String ticketId;
  final String assignedTo;

  const AssignTicketParams({
    required this.ticketId,
    required this.assignedTo,
  });
}

class AssignTicketUseCase implements UseCase<void, AssignTicketParams> {
  final TicketRepository repository;

  AssignTicketUseCase(this.repository);

  @override
  Future<void> call(AssignTicketParams params) async {
    return await repository.assignTicket(params.ticketId, params.assignedTo);
  }
}

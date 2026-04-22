// lib/domain/usecases/ticket/update_ticket_status_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';
import '../../../core/usecases/usecase.dart';

class UpdateTicketStatusParams {
  final String ticketId;
  final TicketStatus status;

  const UpdateTicketStatusParams({
    required this.ticketId,
    required this.status,
  });
}

class UpdateTicketStatusUseCase
    implements UseCase<void, UpdateTicketStatusParams> {
  final TicketRepository repository;

  UpdateTicketStatusUseCase(this.repository);

  @override
  Future<void> call(UpdateTicketStatusParams params) async {
    return await repository.updateTicketStatus(params.ticketId, params.status);
  }
}

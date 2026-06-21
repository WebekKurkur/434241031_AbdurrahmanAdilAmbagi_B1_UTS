// lib/domain/usecases/ticket/get_ticket_history_usecase.dart
//
// Phase A2: ticket history (FR-010, BR-005).

import '../../entities/ticket_entity.dart';
import '../../repositories/ticket_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetTicketHistoryParams {
  final String ticketId;
  const GetTicketHistoryParams({required this.ticketId});
}

class GetTicketHistoryUseCase
    implements UseCase<List<TicketHistoryEntity>, GetTicketHistoryParams> {
  final TicketRepository repository;
  GetTicketHistoryUseCase(this.repository);

  @override
  Future<List<TicketHistoryEntity>> call(GetTicketHistoryParams params) {
    return repository.getTicketHistory(params.ticketId);
  }
}

// lib/domain/usecases/ticket/delete_ticket_usecase.dart
//
// Phase I: admin-only ticket deletion.
//
// Wraps `TicketRepository.deleteTicket` so the use-case layer stays
// the single boundary for cross-cutting concerns (logging, role
// guard checks, analytics). The actual authorization happens
// server-side via `admin_delete_ticket` RPC; this use-case exists
// to give the presentation layer a stable call site and to make
// the dependency graph clear.

import '../../repositories/ticket_repository.dart';
import '../../../core/usecases/usecase.dart';

class DeleteTicketUseCase implements UseCase<void, String> {
  final TicketRepository _repository;

  DeleteTicketUseCase(this._repository);

  @override
  Future<void> call(String ticketUuid) {
    // Defensive: a blank UUID would cause a 22P02 invalid_text
    // error from Postgres. Surface it as a client-side validation
    // failure instead.
    if (ticketUuid.trim().isEmpty) {
      throw ArgumentError('ticketUuid must not be empty');
    }
    return _repository.deleteTicket(ticketUuid);
  }
}
// lib/domain/usecases/ticket/add_ticket_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/ticket_entity.dart';
import '../../../core/usecases/usecase.dart';

/// Inputs the user can supply when creating a new ticket.
///
/// **Why this is not a `TicketEntity`:** the data source generates
/// the public `ticket_code` (e.g. "TKT-001") and the
/// `created_at` server-side, and uses `auth.uid()` for
/// `created_by`. Any client-supplied `id`, `createdAt`,
/// `createdBy`, `status`, or `comments` would be silently
/// ignored — and worse, would tempt a future refactor to trust
/// them. The data source's `addTicket({title, description,
/// category, imageUrl})` named-args signature enforces "only
/// the user-provided fields" at the type level, so we mirror
/// that here.
class AddTicketParams {
  final String title;
  final String description;
  final String category;
  final String? imageUrl;

  const AddTicketParams({
    required this.title,
    required this.description,
    this.category = 'General',
    this.imageUrl,
  });
}

class AddTicketUseCase implements UseCase<TicketEntity, AddTicketParams> {
  final TicketRepository repository;

  AddTicketUseCase(this.repository);

  @override
  Future<TicketEntity> call(AddTicketParams params) {
    return repository.addTicket(params);
  }
}

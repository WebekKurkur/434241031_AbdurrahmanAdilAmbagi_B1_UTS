// lib/domain/usecases/ticket/add_comment_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Parameters for inserting a comment on a ticket.
///
/// The author and the role are intentionally **not** part of the
/// contract: the data source reads `auth.uid()` server-side and
/// the comment row stores `author_id` (a uuid FK to `profiles.id`).
/// Any client-supplied `author` / `role` would be either ignored
/// (current behavior) or a security hole, so the use case never
/// accepts them. The UI gets the commenter's name + role from a
/// `profiles` join on read, not from the write payload.
class AddCommentParams {
  final String ticketId;
  final String message;

  const AddCommentParams({
    required this.ticketId,
    required this.message,
  });
}

class AddCommentUseCase implements UseCase<void, AddCommentParams> {
  final TicketRepository repository;

  AddCommentUseCase(this.repository);

  @override
  Future<void> call(AddCommentParams params) {
    return repository.addComment(params.ticketId, params.message);
  }
}

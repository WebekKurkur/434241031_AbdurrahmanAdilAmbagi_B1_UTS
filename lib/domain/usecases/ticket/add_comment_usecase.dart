// lib/domain/usecases/ticket/add_comment_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/user_entity.dart';

class AddCommentUseCase {
  final TicketRepository repository;

  AddCommentUseCase(this.repository);

  Future<void> call(
    String ticketId,
    String message,
    String author,
    UserRole role,
  ) async {
    return await repository.addComment(ticketId, message, author, role);
  }
}

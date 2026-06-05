// lib/domain/usecases/ticket/add_comment_usecase.dart

import '../../repositories/ticket_repository.dart';
import '../../entities/user_entity.dart';
import '../../../core/usecases/usecase.dart';

class AddCommentParams {
  final String ticketId;
  final String message;
  final String author;
  final UserRole role;

  const AddCommentParams({
    required this.ticketId,
    required this.message,
    required this.author,
    required this.role,
  });
}

class AddCommentUseCase implements UseCase<void, AddCommentParams> {
  final TicketRepository repository;

  AddCommentUseCase(this.repository);

  @override
  Future<void> call(AddCommentParams params) async {
    return await repository.addComment(
      params.ticketId,
      params.message,
      params.author,
      params.role,
    );
  }
}

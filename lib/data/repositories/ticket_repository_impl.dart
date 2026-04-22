// lib/data/repositories/ticket_repository_impl.dart

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_datasource.dart';
import '../models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketDataSource dataSource;

  TicketRepositoryImpl(this.dataSource);

  @override
  Future<List<TicketEntity>> getTickets() async {
    final models = await dataSource.getTickets();
    return models.cast<TicketEntity>();
  }

  @override
  Future<TicketEntity?> getTicketById(String id) async {
    return await dataSource.getTicketById(id);
  }

  @override
  Future<void> addTicket(TicketEntity ticket) async {
    final model = TicketModel.fromEntity(ticket);
    return await dataSource.addTicket(model);
  }

  @override
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    return await dataSource.updateTicketStatus(ticketId, status);
  }

  @override
  Future<void> assignTicket(String ticketId, String assignedTo) async {
    return await dataSource.assignTicket(ticketId, assignedTo);
  }

  @override
  Future<void> addComment(
    String ticketId,
    String message,
    String author,
    UserRole role,
  ) async {
    final comment = CommentModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      message: message,
      createdAt: DateTime.now(),
      role: role,
    );
    return await dataSource.addComment(ticketId, comment);
  }
}

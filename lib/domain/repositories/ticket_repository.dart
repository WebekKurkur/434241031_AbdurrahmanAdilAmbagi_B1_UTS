// lib/domain/repositories/ticket_repository.dart

import '../entities/ticket_entity.dart';
import '../entities/user_entity.dart';

abstract class TicketRepository {
  Future<List<TicketEntity>> getTickets();
  Future<TicketEntity?> getTicketById(String id);
  Future<void> addTicket(TicketEntity ticket);
  Future<void> updateTicketStatus(String ticketId, TicketStatus status);
  Future<void> assignTicket(String ticketId, String assignedTo);
  Future<void> addComment(
    String ticketId,
    String message,
    String author,
    UserRole role,
  );
}

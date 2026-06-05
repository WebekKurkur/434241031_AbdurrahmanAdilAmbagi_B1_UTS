// lib/domain/repositories/ticket_repository.dart

import 'dart:typed_data';

import '../entities/ticket_entity.dart';
import '../entities/user_entity.dart';

class HelpdeskUserSummary {
  final String id;
  final String username;
  final String name;
  final String department;
  const HelpdeskUserSummary({
    required this.id,
    required this.username,
    required this.name,
    required this.department,
  });
}

abstract class TicketRepository {
  Future<List<TicketEntity>> getTickets();
  Future<TicketEntity?> getTicketById(String id);
  Future<TicketEntity> addTicket(TicketEntity ticket);
  Future<void> updateTicketStatus(String ticketId, TicketStatus status);
  Future<void> assignTicket(String ticketId, String assignedTo);
  Future<void> addComment(
    String ticketId,
    String message,
    String author,
    UserRole role,
  );
  Future<List<HelpdeskUserSummary>> getHelpdeskUsers();

  /// Upload [bytes] to the `attachments` Storage bucket under
  /// `tickets/<subdir>/<timestamp>.<ext>` and return the public URL.
  /// [subdir] is typically the ticket's `ticket_code` or a uuid.
  Future<String> uploadTicketImage({
    required Uint8List bytes,
    required String fileName,
    required String subdir,
  });
}

// lib/domain/repositories/ticket_repository.dart

import 'dart:typed_data';

import '../entities/ticket_entity.dart';
import '../usecases/ticket/add_ticket_usecase.dart';

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

  /// Phase G1: paginated ticket read (FR §4.1).
  ///
  /// Returns up to `pageSize` rows starting at offset [from],
  /// optionally filtered by [statusFilter]. See the data source
  /// for the underlying PostgREST semantics.
  Future<List<TicketEntity>> getTicketsPage({
    required int from,
    required int to,
    TicketStatus? statusFilter,
    int pageSize = 20,
  });

  /// Phase G1: total ticket count under the current RLS context,
  /// optionally filtered by status.
  Future<int> countTicketsWithFilter({TicketStatus? statusFilter});

  /// Insert a new ticket and return the server-assigned row.
  ///
  /// The data source generates the public `ticket_code` and
  /// `created_at` server-side, and uses `auth.uid()` for
  /// `created_by`. The caller therefore only supplies the four
  /// user-provided fields through [AddTicketParams].
  Future<TicketEntity> addTicket(AddTicketParams params);

  Future<void> updateTicketStatus(String ticketId, TicketStatus status);
  Future<void> assignTicket(String ticketId, String assignedTo);

  /// Admin-only hard delete. Throws if the caller is not admin.
  /// Cascades to comments, ticket_history, and notifications.
  /// Best-effort removes the attached image from the
  /// `ticket-images` storage bucket.
  Future<void> deleteTicket(String ticketUuid);

  /// Insert a comment on the given ticket.
  ///
  /// The author and role are **not** part of the contract: the
  /// data source reads `auth.uid()` server-side and the row's
  /// `author_id` column is a uuid FK to `profiles.id`. The comment
  /// view joins on `profiles` to hydrate the author's display
  /// name and role on read.
  Future<void> addComment(String ticketId, String message);

  /// Realtime stream of comments for one ticket.
  ///
  /// Emits the current list of comments on subscription AND on
  /// every Supabase `comments` table event (INSERT / UPDATE /
  /// DELETE). The caller may pass either a public `ticket_code`
  /// (e.g. "TKT-001") or the row's uuid — both are resolved
  /// internally.
  ///
  /// Errors are propagated through the stream. Consumers that
  /// just want the initial snapshot can fall back to
  /// [getTicketById].
  Stream<List<CommentEntity>> watchComments(String ticketId);

  /// One-shot read of the per-ticket audit log (FR-010, BR-005).
  /// Returns rows in reverse chronological order (newest first).
  /// The caller may pass either a public `ticket_code` or the
  /// row's uuid.
  Future<List<TicketHistoryEntity>> getTicketHistory(String ticketId);

  /// Realtime stream of the per-ticket audit log. Emits the
  /// current list on subscription AND on every `ticket_history`
  /// event (which is triggered by INSERT/UPDATE on `tickets` and
  /// INSERT on `comments` — see migration `0003_ticket_history.sql`).
  Stream<List<TicketHistoryEntity>> watchTicketHistory(String ticketId);

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

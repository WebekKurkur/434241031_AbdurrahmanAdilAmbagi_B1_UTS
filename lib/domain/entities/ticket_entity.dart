// lib/domain/entities/ticket_entity.dart

import 'user_entity.dart';

/// Ticket lifecycle states.
///
/// Workflow:
///   open        → user just created it, no helpdesk assigned yet
///   assigned    → admin picked a helpdesk, work hasn't started
///   inProgress  → helpdesk is actively working on it
///   closed      → terminal state (work done, ticket shut)
///
/// Matches the `tickets_status_check` constraint in
/// `supabase/migrations/0002_add_assign_and_closed.sql`.
enum TicketStatus { open, assigned, inProgress, closed }

class CommentEntity {
  final String id;
  final String author;
  final String message;
  final DateTime createdAt;
  final UserRole role;

  CommentEntity({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
    required this.role,
  });
}

class TicketEntity {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;
  final String createdBy;
  final String? assignedTo;
  final List<CommentEntity> comments;
  final String? imageUrl;
  final String category;

  TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.assignedTo,
    this.comments = const [],
    this.imageUrl,
    this.category = 'General',
  });

  TicketEntity copyWith({
    String? title,
    String? description,
    TicketStatus? status,
    String? assignedTo,
    List<CommentEntity>? comments,
    String? imageUrl,
  }) {
    return TicketEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      comments: comments ?? this.comments,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category,
    );
  }
}

/// One row of the `ticket_history` audit log.
///
/// Populated by Postgres triggers on `tickets` (insert/update) and
/// `comments` (insert). See `supabase/migrations/0003_ticket_history.sql`.
///
/// [action] is one of:
///   - 'created'         — ticket was created
///   - 'assigned'        — `assigned_to` was changed
///   - 'status_changed'  — status changed (open/assigned/inProgress)
///   - 'closed'          — status changed to 'closed' (terminal)
///   - 'commented'       — a comment was added
class TicketHistoryEntity {
  final String id;
  final String ticketId;
  final String? actorId;
  final String? actorName;     // joined from profiles (may be null if user was deleted)
  final String action;
  final String? fromValue;
  final String? toValue;
  final String? note;
  final DateTime createdAt;

  const TicketHistoryEntity({
    required this.id,
    required this.ticketId,
    this.actorId,
    this.actorName,
    required this.action,
    this.fromValue,
    this.toValue,
    this.note,
    required this.createdAt,
  });
}

// lib/domain/entities/notification_entity.dart
//
// Phase B1 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// One row of the `notifications` table. Populated by Postgres
// triggers on `tickets` UPDATE (assigned, status_changed, closed)
// and `comments` INSERT (commented). See
// `supabase/migrations/0005_notifications.sql`.
//
// [type] is one of:
//   - 'assigned'        — a ticket was assigned to the recipient
//   - 'status_changed'  — status changed on the recipient's ticket
//   - 'commented'       — someone replied on the recipient's ticket
//   - 'closed'          — the recipient's ticket was closed

class NotificationEntity {
  final String id;
  final String userId;
  final String ticketId;
  final String? actorId;
  final String? actorName;   // joined from profiles
  final String type;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.ticketId,
    this.actorId,
    this.actorName,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  NotificationEntity copyWith({DateTime? readAt}) {
    return NotificationEntity(
      id: id,
      userId: userId,
      ticketId: ticketId,
      actorId: actorId,
      actorName: actorName,
      type: type,
      title: title,
      body: body,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
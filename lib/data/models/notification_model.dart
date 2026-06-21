// lib/data/models/notification_model.dart
//
// Phase B1 of the SRS v2.0.0 audit.

import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.ticketId,
    super.actorId,
    super.actorName,
    required super.type,
    required super.title,
    required super.body,
    super.readAt,
    required super.createdAt,
  });

  factory NotificationModel.fromRow(Map<String, dynamic> row) {
    final actor = row['actor'] as Map<String, dynamic>?;
    return NotificationModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      ticketId: row['ticket_id'] as String,
      actorId: row['actor_id'] as String?,
      actorName: actor?['name'] as String?,
      type: row['type'] as String,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      readAt: row['read_at'] == null
          ? null
          : DateTime.parse(row['read_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
// lib/data/models/ticket_model.dart

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({
    required String id,
    required String author,
    required String message,
    required DateTime createdAt,
    required UserRole role,
  }) : super(
    id: id,
    author: author,
    message: message,
    createdAt: createdAt,
    role: role,
  );

  factory CommentModel.fromEntity(CommentEntity entity) {
    return CommentModel(
      id: entity.id,
      author: entity.author,
      message: entity.message,
      createdAt: entity.createdAt,
      role: entity.role,
    );
  }
}

class TicketModel extends TicketEntity {
  TicketModel({
    required String id,
    required String title,
    required String description,
    required TicketStatus status,
    required DateTime createdAt,
    required String createdBy,
    String? assignedTo,
    List<CommentModel> comments = const [],
    String? imageUrl,
    String category = 'General',
  }) : super(
    id: id,
    title: title,
    description: description,
    status: status,
    createdAt: createdAt,
    createdBy: createdBy,
    assignedTo: assignedTo,
    comments: comments,
    imageUrl: imageUrl,
    category: category,
  );

  factory TicketModel.fromEntity(TicketEntity entity) {
    return TicketModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      assignedTo: entity.assignedTo,
      comments: entity.comments
          .map((c) => CommentModel.fromEntity(c))
          .toList()
          .cast<CommentModel>(),
      imageUrl: entity.imageUrl,
      category: entity.category,
    );
  }

  @override
  TicketModel copyWith({
    String? title,
    String? description,
    TicketStatus? status,
    String? assignedTo,
    List<CommentEntity>? comments,
    String? imageUrl,
  }) {
    return TicketModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      comments: (comments ?? this.comments)
          .map((c) => c is CommentModel ? c : CommentModel.fromEntity(c))
          .toList()
          .cast<CommentModel>(),
      imageUrl: imageUrl ?? this.imageUrl,
      category: category,
    );
  }
}

/// Data-layer wrapper for `TicketHistoryEntity`.
///
/// Built from a `ticket_history` row joined with `profiles` for the
/// actor's display name.
class TicketHistoryModel extends TicketHistoryEntity {
  const TicketHistoryModel({
    required super.id,
    required super.ticketId,
    super.actorId,
    super.actorName,
    required super.action,
    super.fromValue,
    super.toValue,
    super.note,
    required super.createdAt,
  });

  factory TicketHistoryModel.fromRow(Map<String, dynamic> row) {
    // The join: `actor:actor_id(name)`. If the actor was deleted
    // (cascade set null), `row['actor']` is null.
    final actor = row['actor'] as Map<String, dynamic>?;
    return TicketHistoryModel(
      id: row['id'] as String,
      ticketId: row['ticket_id'] as String,
      actorId: row['actor_id'] as String?,
      actorName: actor?['name'] as String?,
      action: row['action'] as String,
      fromValue: row['from_value'] as String?,
      toValue: row['to_value'] as String?,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

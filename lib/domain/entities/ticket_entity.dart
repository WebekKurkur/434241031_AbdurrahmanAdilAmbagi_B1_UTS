// lib/domain/entities/ticket_entity.dart

import 'user_entity.dart';

enum TicketStatus { open, inProgress, done }

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

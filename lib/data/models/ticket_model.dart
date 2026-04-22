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

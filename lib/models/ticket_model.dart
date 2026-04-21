// lib/models/ticket_model.dart

enum TicketStatus { open, inProgress, done }

enum UserRole { user, helpdesk, admin }

class Comment {
  final String id;
  final String author;
  final String message;
  final DateTime createdAt;
  final UserRole role;

  Comment({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
    required this.role,
  });
}

class Ticket {
  final String id;
  String title;
  String description;
  TicketStatus status;
  final DateTime createdAt;
  final String createdBy;
  String? assignedTo;
  List<Comment> comments;
  String? imageUrl;
  String category;

  Ticket({
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

  Ticket copyWith({
    String? title,
    String? description,
    TicketStatus? status,
    String? assignedTo,
    List<Comment>? comments,
    String? imageUrl,
    String? category,
  }) {
    return Ticket(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      comments: comments ?? this.comments,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final UserRole role;
  final String avatarUrl;
  final String department;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.department,
  });
}

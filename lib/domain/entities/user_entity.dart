// lib/domain/entities/user_entity.dart

enum UserRole { user, helpdesk, admin }

class UserEntity {
  final String id;
  final String name;
  final String username;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String department;

  UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.department,
  });
}

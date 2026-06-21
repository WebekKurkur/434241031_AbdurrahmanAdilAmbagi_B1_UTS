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

  /// Phase E: whether the profile is active. Inactive users
  /// cannot sign in (the data source's login flow refuses to
  /// hydrate them, and an admin can flip the flag from the
  /// user-management screen).
  final bool isActive;

  UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.department,
    this.isActive = true,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? department,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
    );
  }
}

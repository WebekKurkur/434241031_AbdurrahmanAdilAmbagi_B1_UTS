// lib/data/models/user_model.dart

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    required super.role,
    super.avatarUrl,
    required super.department,
    super.isActive = true,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      username: entity.username,
      email: entity.email,
      role: entity.role,
      avatarUrl: entity.avatarUrl,
      department: entity.department,
      isActive: entity.isActive,
    );
  }

  /// Parse a `profiles` row returned by PostgREST.
  ///
  /// Phase E: also reads `is_active` (default true for older
  /// rows written before migration 0006).
  factory UserModel.fromRow(Map<String, dynamic> j) {
    return UserModel(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      username: j['username'] as String? ?? '',
      email: j['email'] as String? ?? '',
      role: _parseRole(j['role'] as String? ?? 'user'),
      avatarUrl: j['avatar_url'] as String?,
      department: j['department'] as String? ?? '',
      isActive: j['is_active'] as bool? ?? true,
    );
  }

  static UserRole _parseRole(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == s,
      orElse: () => UserRole.user,
    );
  }
}
// lib/data/models/user_model.dart

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    required String name,
    required String username,
    required String email,
    required UserRole role,
    String? avatarUrl,
    required String department,
  }) : super(
    id: id,
    name: name,
    username: username,
    email: email,
    role: role,
    avatarUrl: avatarUrl,
    department: department,
  );

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      username: entity.username,
      email: entity.email,
      role: entity.role,
      avatarUrl: entity.avatarUrl,
      department: entity.department,
    );
  }
}

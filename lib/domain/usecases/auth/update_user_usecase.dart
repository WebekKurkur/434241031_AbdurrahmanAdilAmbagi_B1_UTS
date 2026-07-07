// lib/domain/usecases/auth/update_user_usecase.dart
//
// Phase E of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-007: Admin updates another user's role / active state /
// department via the `admin_update_user` RPC.

import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class UpdateUserParams {
  final String targetUserId;
  final UserRole? role;
  final bool? isActive;
  final String? department;

  const UpdateUserParams({
    required this.targetUserId,
    this.role,
    this.isActive,
    this.department,
  });
}

class UpdateUserUseCase {
  final AuthRepository repository;
  UpdateUserUseCase(this.repository);

  Future<UserEntity> call(UpdateUserParams params) {
    return repository.adminUpdateUser(
      targetUserId: params.targetUserId,
      role: params.role,
      isActive: params.isActive,
      department: params.department,
    );
  }
}
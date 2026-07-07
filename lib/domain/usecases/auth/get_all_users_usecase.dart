// lib/domain/usecases/auth/get_all_users_usecase.dart
//
// Phase E of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-007: Admin manages user list. Returns every profile row.

import '../../../core/usecases/usecase.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class GetAllUsersUseCase extends NoParamsUseCase<List<UserEntity>> {
  final AuthRepository repository;
  GetAllUsersUseCase(this.repository);

  @override
  Future<List<UserEntity>> call() {
    return repository.getAllUsers();
  }
}
// lib/domain/usecases/auth/register_usecase.dart
//
// Phase C1 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-003: Register. Calls `supabase.auth.signUp()` and returns
// the freshly created user. The `handle_new_user` Postgres
// trigger creates the matching `profiles` row.

import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class RegisterParams {
  final String username;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String department;

  const RegisterParams({
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.department,
  });
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity?> call(RegisterParams params) {
    return repository.register(
      username: params.username,
      name: params.name,
      email: params.email,
      password: params.password,
      role: params.role,
      department: params.department,
    );
  }
}
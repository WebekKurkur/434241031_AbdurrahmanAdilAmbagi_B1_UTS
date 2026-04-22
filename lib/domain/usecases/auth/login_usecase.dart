// lib/domain/usecases/auth/login_usecase.dart

import '../../repositories/auth_repository.dart';
import '../../entities/user_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity?> call(String username, String password) async {
    return await repository.login(username, password);
  }
}

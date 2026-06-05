// lib/domain/usecases/auth/login_usecase.dart

import '../../repositories/auth_repository.dart';
import '../../entities/user_entity.dart';
import '../../../core/usecases/usecase.dart';

class LoginParams {
  final String username;
  final String password;

  const LoginParams({
    required this.username,
    required this.password,
  });
}

class LoginUseCase implements UseCase<UserEntity?, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<UserEntity?> call(LoginParams params) async {
    return await repository.login(params.username, params.password);
  }
}

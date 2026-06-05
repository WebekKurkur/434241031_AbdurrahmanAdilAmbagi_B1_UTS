// lib/domain/usecases/auth/logout_usecase.dart

import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<void> call() async {
    repository.logout();
  }
}

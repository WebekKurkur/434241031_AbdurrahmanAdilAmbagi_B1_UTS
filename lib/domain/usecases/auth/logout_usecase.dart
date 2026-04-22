// lib/domain/usecases/auth/logout_usecase.dart

import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  void call() {
    repository.logout();
  }
}

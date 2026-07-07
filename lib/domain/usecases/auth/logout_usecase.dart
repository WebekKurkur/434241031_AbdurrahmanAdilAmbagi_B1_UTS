// lib/domain/usecases/auth/logout_usecase.dart

import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<void> call() {
    // `repository.logout()` is `Future<void>` and rethrows on
    // failure, so we just await it. The `AuthNotifier.logout()`
    // caller awaits this and surfaces any error to the user.
    return repository.logout();
  }
}

// lib/domain/usecases/auth/reset_password_usecase.dart
//
// Phase C2 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-004: Reset Password. Calls
// `supabase.auth.resetPasswordForEmail()` and triggers a one-time
// reset link to the supplied email.

import '../../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call(String email) {
    return repository.resetPassword(email);
  }
}
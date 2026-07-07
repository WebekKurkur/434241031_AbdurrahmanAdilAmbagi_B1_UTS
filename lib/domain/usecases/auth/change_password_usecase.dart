// lib/domain/usecases/auth/change_password_usecase.dart
//
// 2026-06-25 update: replaces the email-based resetPassword flow.
// The user enters their email + old password + new password on
// the forgot-password screen. We verify the old password (via
// sign-in) then update the auth row.

import '../../repositories/auth_repository.dart';

class ChangePasswordParams {
  final String email;
  final String oldPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.email,
    required this.oldPassword,
    required this.newPassword,
  });
}

class ChangePasswordUseCase {
  final AuthRepository repository;
  ChangePasswordUseCase(this.repository);

  Future<void> call(ChangePasswordParams params) {
    return repository.changePassword(
      email: params.email,
      oldPassword: params.oldPassword,
      newPassword: params.newPassword,
    );
  }
}

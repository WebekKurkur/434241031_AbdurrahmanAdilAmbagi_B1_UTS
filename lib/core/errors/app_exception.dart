// lib/core/errors/app_exception.dart

class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() {
    if (code == null) return message;
    return '$code: $message';
  }
}

/// Phase E: thrown by [AuthRepository.login] when the matching
/// profile has `is_active = false`. The login screen catches
/// this and shows a friendly "akun dinonaktifkan" message.
class UserInactiveException extends AppException {
  const UserInactiveException()
      : super(message: 'Akun Anda telah dinonaktifkan. Hubungi admin.', code: 'USER_INACTIVE');
}

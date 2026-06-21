// lib/domain/repositories/auth_repository.dart

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String username, String password);

  /// Sign the current user out.
  ///
  /// Returns normally on success. Throws if the underlying
  /// `supabase.auth.signOut()` call fails (network error, no
  /// session, etc.) so callers can surface a snackbar instead of
  /// silently routing the user to `/login` while the session is
  /// still alive on the server.
  Future<void> logout();

  UserEntity? get currentUser;
}

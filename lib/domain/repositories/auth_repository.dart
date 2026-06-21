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

  /// Create a new user account and hydrate the matching `profiles`
  /// row. Used by the register screen (FR-003).
  ///
  /// Throws if the underlying `supabase.auth.signUp()` call fails
  /// (email already taken, weak password, network error, etc.) so
  /// the UI can show a snackbar with the original error message
  /// instead of silently routing the user somewhere.
  Future<UserEntity?> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String department,
  });

  /// Trigger a password-reset email. Used by the forgot-password
  /// screen (FR-004).
  ///
  /// Throws on failure so the UI can surface a snackbar with the
  /// error message instead of silently reporting success.
  Future<void> resetPassword(String email);

  /// Phase E: list all profiles (admin-only UI gate; the read
  /// policy itself is open to any authenticated user).
  Future<List<UserEntity>> getAllUsers();

  /// Phase E: call `admin_update_user` RPC. The server enforces
  /// role + validates the role argument; the client just forwards
  /// the desired final values.
  Future<UserEntity> adminUpdateUser({
    required String targetUserId,
    UserRole? role,
    bool? isActive,
    String? department,
  });

  UserEntity? get currentUser;
}

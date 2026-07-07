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

  /// Self-serve password change. Replaces the email-based
  /// reset link: we verify the user knows the existing
  /// password by attempting a sign-in, then call
  /// `auth.updateUser({password: newPassword})`. The user lands
  /// signed-in (the verify signInWithPassword creates a
  /// session), so we sign them back out at the end to keep
  /// the `/login` landing explicit.
  ///
  /// Throws if `oldPassword` is wrong (the sign-in fails) or
  /// if the updateUser call is rejected by Auth (weak
  /// password, network error, etc.). The UI surfaces the
  /// message verbatim.
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  });

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

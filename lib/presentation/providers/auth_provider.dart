// lib/presentation/providers/auth_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/network/supabase_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/auth/get_all_users_usecase.dart';
import '../../domain/usecases/auth/update_user_usecase.dart';

// Data Sources
final authDataSourceProvider = Provider((ref) => AuthDataSource());

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// Use Cases
final loginUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final registerUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

// Phase E: admin user management
final getAllUsersUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetAllUsersUseCase(repository);
});

final updateUserUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateUserUseCase(repository);
});

/// Phase E: list of all profiles (admin only). Refreshable via
/// `ref.invalidate(adminUsersProvider)`.
final adminUsersProvider =
    FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final useCase = ref.watch(getAllUsersUseCaseProvider);
  return await useCase();
});

/// Auth state notifier.
///
/// Subscribes once to the Supabase-backed [AuthDataSource.profileStream] in
/// its constructor and updates its own [state] in response. We intentionally
/// do **not** depend on [authStateProvider] in [currentUserProvider] — that
/// would cause the notifier to be disposed and rebuilt every time Supabase
/// fires an auth event, racing the in-flight `state = …` writes from
/// `login()` / the stream listener (see "Bad state: Tried to use
/// AuthNotifier after dispose was called").
class AuthNotifier extends StateNotifier<UserEntity?> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final AuthDataSource dataSource;
  StreamSubscription<UserEntity?>? _profileSub;

  AuthNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.resetPasswordUseCase,
    required this.updateUserUseCase,
    required this.dataSource,
    required UserEntity? initialUser,
  }) : super(initialUser) {
    // Keep the state in sync with Supabase auth events
    // (SIGNED_IN on cold start, SIGNED_OUT, TOKEN_REFRESHED, …).
    _profileSub = dataSource.profileStream.listen((user) {
      // Guard against late events arriving after dispose (e.g. when the
      // app shuts down). `mounted` is provided by `StateNotifier`.
      if (!mounted) return;
      state = user;
    });
  }

  Future<bool> login(String username, String password) async {
    final user = await loginUseCase(
      LoginParams(username: username, password: password),
    );
    if (!mounted) return user != null;
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  /// Create a new account. Returns the freshly created user (or
  /// `null` if the server rejected the request). On success the
  /// `profileStream` listener above will pick up the new session
  /// and update `state` automatically, so we don't write to `state`
  /// ourselves here.
  Future<UserEntity?> register(RegisterParams params) async {
    final user = await registerUseCase(params);
    return user;
  }

  /// Trigger a password-reset email. Throws on failure so the UI
  /// can surface the error message. Used by the forgot-password
  /// screen (FR-004).
  Future<void> resetPassword(String email) async {
    await resetPasswordUseCase(email);
  }

  /// Phase E: update another user's profile via the
  /// `admin_update_user` RPC. Returns the updated entity so the
  /// caller can update local optimistic state.
  Future<UserEntity> updateUser(UpdateUserParams params) async {
    final updated = await updateUserUseCase(params);
    // The currently signed-in admin may have changed their own
    // department / avatar through this call too. Refresh the
    // local user entity if so.
    if (mounted && state?.id == params.targetUserId) {
      state = updated;
    }
    return updated;
  }

  /// Sign the current user out and clear local state.
  ///
  /// Awaits the underlying `supabase.auth.signOut()` call and only
  /// nulls the state on success. If `signOut` throws (network drop,
  /// no session, etc.) the exception propagates to the caller so the
  /// UI can show a snackbar instead of silently routing the user to
  /// `/login` while the session is still alive on the server.
  Future<void> logout() async {
    await logoutUseCase();
    if (!mounted) return;
    state = null;
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _profileSub = null;
    super.dispose();
  }
}

/// The currently signed-in user. Marked `keepAlive: true` so the
/// notifier survives rebuilds of unrelated providers (the only thing
/// that should ever rebuild it is the user calling `ref.invalidate`
/// explicitly, which we don't do).
final currentUserProvider =
    StateNotifierProvider<AuthNotifier, UserEntity?>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  final repository = ref.watch(authRepositoryProvider);

  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
    updateUserUseCase: ref.watch(updateUserUseCaseProvider),
    dataSource: dataSource,
    initialUser: repository.currentUser,
  );
}, name: 'currentUserProvider');

/// Convenience: is the user currently signed in?
final isLoggedInProvider = Provider((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// When the current user's password was last updated. `null`
/// if no session or the auth row has no `updated_at`. Drives
/// the "Last updated X days ago" subtitle on the settings
/// screen's "Change password" row.
final passwordUpdatedAtProvider = Provider<DateTime?>((ref) {
  return ref.watch(authDataSourceProvider).passwordUpdatedAt;
});

/// Async profile lookup. Resolves the current Supabase session and
/// hydrates the matching `profiles` row. Use this on the splash
/// screen to decide whether to navigate to `/login` or `/home`.
///
/// Unlike [currentUserProvider] (which is a sync `StateNotifier`),
/// this provider performs a real DB read so cold starts return a
/// fully-hydrated user even when the previous session is being
/// restored from `flutter_secure_storage`.
///
/// All exceptions are swallowed and returned as `null`. The splash
/// screen treats a `null` result as "no session" and routes to
/// `/login`. A failure here is never fatal — the user can always
/// sign in fresh.
final currentProfileProvider = FutureProvider<UserEntity?>((ref) async {
  // Watch the auth state so we re-run the lookup on every
  // SIGNED_IN / SIGNED_OUT / TOKEN_REFRESHED event.
  ref.watch(authStateProvider);
  final dataSource = ref.watch(authDataSourceProvider);
  try {
    // Hard 4-second timeout. Supabase cold start can occasionally
    // stall on a network handshake; we'd rather show `/login` than
    // hang the splash screen.
    return await dataSource
        .getCurrentProfile()
        .timeout(const Duration(seconds: 4), onTimeout: () => null);
  } catch (e, st) {
    // Defensive: any exception is treated as "no session" so the
    // splash can always navigate somewhere.
    debugPrint('[Auth] currentProfileProvider failed: $e\n$st');
    return null;
  }
});

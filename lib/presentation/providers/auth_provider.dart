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
  final AuthDataSource dataSource;
  StreamSubscription<UserEntity?>? _profileSub;

  AuthNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
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
    dataSource: dataSource,
    initialUser: repository.currentUser,
  );
}, name: 'currentUserProvider');

/// Convenience: is the user currently signed in?
final isLoggedInProvider = Provider((ref) {
  return ref.watch(currentUserProvider) != null;
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

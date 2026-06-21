// lib/data/repositories/auth_repository_impl.dart
//
// Bridges the domain layer to the Supabase AuthDataSource.

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<UserEntity?> login(String username, String password) async {
    // The login screen still passes the username. Resolve it to an email
    // first so the user can type `user` / `helpdesk` / `admin` directly.
    String email = username;
    if (!username.contains('@')) {
      final resolved = await dataSource.resolveEmail(username);
      if (resolved == null) return null;
      email = resolved;
    }
    return await dataSource.login(email, password);
  }

  @override
  Future<void> logout() async {
    // `dataSource.logout()` is `Future<void>`, so rethrow any
    // failure (network drop, no session, etc.) up to the notifier
    // so the UI can show a snackbar instead of silently routing
    // the user to `/login` while their session is still alive.
    await dataSource.logout();
  }

  @override
  UserEntity? get currentUser => dataSource.currentUser;
}

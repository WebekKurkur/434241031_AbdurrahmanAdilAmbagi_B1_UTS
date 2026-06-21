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
  Future<UserEntity?> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String department,
  }) async {
    // Forward to the data source. The `handle_new_user` Postgres
    // trigger (migration 0001_init.sql) creates the matching row in
    // `public.profiles` from `auth.users.raw_user_meta_data`.
    return await dataSource.signUp(
      email: email,
      password: password,
      name: name,
      username: username,
      role: role,
      department: department,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    await dataSource.resetPassword(email);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    return await dataSource.getAllUsers();
  }

  @override
  Future<UserEntity> adminUpdateUser({
    required String targetUserId,
    UserRole? role,
    bool? isActive,
    String? department,
  }) async {
    return await dataSource.adminUpdateUser(
      targetUserId: targetUserId,
      role: role,
      isActive: isActive,
      department: department,
    );
  }

  @override
  UserEntity? get currentUser => dataSource.currentUser;
}

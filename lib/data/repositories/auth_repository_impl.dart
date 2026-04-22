// lib/data/repositories/auth_repository_impl.dart

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<UserEntity?> login(String username, String password) async {
    if (password != 'password') return null;
    return await dataSource.authenticate(username);
  }

  @override
  void logout() {
    dataSource.logout();
  }

  @override
  UserEntity? get currentUser => dataSource.currentUser;
}

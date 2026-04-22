// lib/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
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

// State Notifier for Auth
class AuthNotifier extends StateNotifier<UserEntity?> {
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(repository.currentUser);

  Future<bool> login(String username, String password) async {
    final user = await repository.login(username, password);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  void logout() {
    repository.logout();
    state = null;
  }
}

// Current User State Provider
final currentUserProvider =
    StateNotifierProvider<AuthNotifier, UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Is Logged In Convenience Provider
final isLoggedInProvider = Provider((ref) {
  return ref.watch(currentUserProvider) != null;
});

// lib/data/datasources/auth_datasource.dart

import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class AuthDataSource {
  final List<UserModel> _users = [
    UserModel(
      id: 'u1',
      name: 'Ahmad Rizki',
      username: 'user',
      email: 'ahmad.rizki@email.com',
      role: UserRole.user,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      department: 'Finance',
    ),
    UserModel(
      id: 'u2',
      name: 'Budi Santoso',
      username: 'helpdesk',
      email: 'budi.santoso@email.com',
      role: UserRole.helpdesk,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      department: 'IT Support',
    ),
    UserModel(
      id: 'u3',
      name: 'Citra Dewi',
      username: 'admin',
      email: 'citra.dewi@email.com',
      role: UserRole.admin,
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      department: 'IT Management',
    ),
  ];

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> authenticate(String username) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      _currentUser = _users.firstWhere((u) => u.username == username);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  void logout() {
    _currentUser = null;
  }
}

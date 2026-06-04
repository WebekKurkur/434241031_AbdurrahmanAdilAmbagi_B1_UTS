// lib/data/datasources/auth_datasource.dart
//
// Supabase-backed implementation. All persistence lives in the database
// (`profiles`) and the global Supabase auth service.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class AuthDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------- public

  /// Synchronous snapshot of the signed-in user from `auth.users` only.
  /// Returns `null` if the user is not signed in.
  ///
  /// Prefer [getCurrentProfile] (async) which always hydrates from
  /// `profiles`. This getter is kept for the rare cases where an
  /// async call is impossible (e.g. constructors of synchronous
  /// providers).
  UserEntity? get currentUser {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    return _userFromAuth(authUser);
  }

  /// Async profile lookup for the currently signed-in user.
  /// Returns `null` if the user is not signed in.
  /// On cold start (a valid session is in storage but no profile
  /// has been loaded yet) this hits the `profiles` table so the
  /// user has a fully-hydrated `UserEntity` (real name, role,
  /// department) instead of just the auth metadata stub.
  Future<UserEntity?> getCurrentProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    return await _fetchProfile(authUser.id) ?? _userFromAuth(authUser);
  }

  /// Sign in with email + password. The `authDataSource` doesn't take
  /// a username — the login screen resolves the username to an email
  /// through the `profiles` table when needed.
  Future<UserEntity?> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) return null;
    return await _fetchProfile(res.user!.id);
  }

  /// Resolve a username to its email. Used by the login screen so the
  /// user can keep typing `user` / `helpdesk` / `admin` instead of an
  /// email address.
  Future<String?> resolveEmail(String username) async {
    final data = await _client
        .from('profiles')
        .select('email')
        .eq('username', username)
        .maybeSingle();
    return data?['email'] as String?;
  }

  /// Sign up a new user. The `handle_new_user` trigger will
  /// automatically create a matching row in `public.profiles`.
  Future<UserEntity?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
    required UserRole role,
    required String department,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'username': username,
        'role': role.name,
        'department': department,
      },
    );
    if (res.user == null) return null;
    return await _fetchProfile(res.user!.id);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Stream the profile (re-fetched on every auth change) so the UI
  /// can react automatically to SIGNED_IN / SIGNED_OUT.
  Stream<UserEntity?> get profileStream => _client.auth.onAuthStateChange
      .asyncMap<UserEntity?>((event) async {
    final session = event.session;
    if (session == null) return null;
    return await _fetchProfile(session.user.id);
  });

  // ------------------------------------------------------------- private

  Future<UserEntity?> _fetchProfile(String id) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return _toEntity(data);
  }

  UserEntity _userFromAuth(User u) => UserModel(
        id: u.id,
        name: (u.userMetadata?['name'] as String?) ?? '',
        username: (u.userMetadata?['username'] as String?) ?? '',
        email: u.email ?? '',
        role: _parseRole((u.userMetadata?['role'] as String?) ?? 'user'),
        department: (u.userMetadata?['department'] as String?) ?? '',
        avatarUrl: u.userMetadata?['avatar_url'] as String?,
      );

  UserEntity _toEntity(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: _parseRole(j['role'] as String? ?? 'user'),
        avatarUrl: j['avatar_url'] as String?,
        department: j['department'] as String? ?? '',
      );

  UserRole _parseRole(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == s,
      orElse: () => UserRole.user,
    );
  }
}

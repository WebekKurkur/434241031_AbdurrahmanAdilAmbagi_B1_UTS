// lib/data/datasources/auth_datasource.dart
//
// Supabase-backed implementation. All persistence lives in the database
// (`profiles`) and the global Supabase auth service.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
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

  /// When the current user's password was last updated (auth
  /// row `updated_at`). `null` if no session. Used by the
  /// settings screen to show a "Last updated X days ago"
  /// subtitle next to "Change password".
  DateTime? get passwordUpdatedAt {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    final iso = u.updatedAt;
    if (iso == null) return null;
    return DateTime.tryParse(iso);
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
  ///
  /// Phase E: if the matching `profiles.is_active` is `false`, this
  /// throws [UserInactiveException] (and signs the user back out).
  /// The login screen catches it and surfaces a friendly message.
  Future<UserEntity?> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) return null;
    final profile = await _fetchProfile(res.user!.id);
    if (profile != null && !profile.isActive) {
      // Deactivated user: sign them right back out so the
      // session doesn't linger server-side.
      await _client.auth.signOut();
      throw const UserInactiveException();
    }
    return profile;
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

  /// Phase E: list all profiles (admin-only via RLS — the
  /// "profiles read" policy allows any authenticated user to
  /// read all profiles, but the admin UI is gated by the caller's
  /// role on the client side and by the admin_update_user RPC on
  /// the server side).
  Future<List<UserEntity>> getAllUsers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('name', ascending: true);
    return rows.map(UserModel.fromRow).toList();
  }

  /// Phase E: call the `admin_update_user` RPC. Returns the
  /// updated row.
  Future<UserEntity> adminUpdateUser({
    required String targetUserId,
    UserRole? role,
    bool? isActive,
    String? department,
  }) async {
    final res = await _client.rpc(
      'admin_update_user',
      params: {
        'p_target': targetUserId,
        if (role != null) 'p_role': role.name,
        if (isActive != null) 'p_is_active': isActive,
        if (department != null) 'p_department': department,
      },
    );
    // Supabase RPC returns a single row as a map when invoked
    // through `.rpc(name, params)`. The `admin_update_user`
    // function returns `public.profiles` so we get a single
    // map back.
    final row = (res as Map).cast<String, dynamic>();
    return UserModel.fromRow(row);
  }

  /// Trigger a password-reset email. Supabase sends a one-time
  /// link to `email` containing a token that the user clicks to
  /// land on the redirect URL (configured per-project).
  ///
  /// Throws on failure (invalid email, network error, rate
  /// limit, etc.) so the caller can surface the error message
  /// instead of silently reporting success.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
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
        isActive: j['is_active'] as bool? ?? true,
      );

  UserRole _parseRole(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == s,
      orElse: () => UserRole.user,
    );
  }
}

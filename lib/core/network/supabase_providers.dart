// lib/core/network/supabase_providers.dart
//
// Centralized Supabase client and auth-state providers.
// Importing this file is enough for any layer to access Supabase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton Supabase client. Backed by [Supabase.initialize]
/// called in `main.dart` before runApp.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Streams auth state changes (SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, …).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Convenience: the currently signed-in auth user (or null).
final authUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

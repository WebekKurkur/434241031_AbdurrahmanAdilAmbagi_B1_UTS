// lib/core/network/connection_test.dart
//
// Lightweight startup probe that verifies the Supabase wiring is correct
// at the moment the app boots. Runs once at splash time, logs the result
// to the console, and exposes the outcome through a Riverpod provider so
// the UI can react if needed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_providers.dart';

class ConnectionStatus {
  final bool ok;
  final String message;
  final int? profilesCount;
  const ConnectionStatus({
    required this.ok,
    required this.message,
    this.profilesCount,
  });

  factory ConnectionStatus.ok(int n) =>
      ConnectionStatus(ok: true, message: 'Connected', profilesCount: n);
  factory ConnectionStatus.fail(String m) =>
      ConnectionStatus(ok: false, message: m);
}

/// Probes the live Supabase project. The `count()` terminal method
/// performs a `SELECT count(*) FROM profiles` under the hood and
/// returns only the count, so no rows are shipped over the wire.
///
/// All exceptions (including timeouts) are caught and returned as
/// a `ConnectionStatus.fail(...)`. The splash screen never hangs on
/// this provider.
final connectionStatusProvider = FutureProvider<ConnectionStatus>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final res = await client
        .from('profiles')
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 4));
    return ConnectionStatus.ok(res);
  } on AuthException catch (e) {
    return ConnectionStatus.fail('Auth: ${e.message}');
  } on PostgrestException catch (e) {
    return ConnectionStatus.fail('PostgREST: ${e.message}');
  } catch (e) {
    return ConnectionStatus.fail('Network: $e');
  }
});

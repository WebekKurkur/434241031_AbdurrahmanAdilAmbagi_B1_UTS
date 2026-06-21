// lib/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connection_test.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Show splash for at least 1.2s for the animation, then wait for
    // the Supabase probe AND the profile hydration to finish.
    // The profile lookup is what makes cold-start navigation work:
    // if a valid session is in `flutter_secure_storage`, we land on
    // `/home`; otherwise we land on `/login`.
    //
    // We use `.valueOrNull` instead of `.future` for the providers
    // so that an error state on either one returns `null` rather
    // than rejecting. This means the splash ALWAYS navigates
    // somewhere — no matter what happens with the network.
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      final status =
          ref.read(connectionStatusProvider).valueOrNull;
      final profile =
          ref.read(currentProfileProvider).valueOrNull;
      final profileStr = profile != null ? 'restored' : 'none';
      final statusStr = status != null
          ? '${status.ok ? "OK" : "FAIL"} — ${status.message}'
              '${status.profilesCount != null ? " (profiles=${status.profilesCount})" : ""}'
          : 'no-status';
      debugPrint('[Supabase] $statusStr | session=$profileStr');
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        profile != null ? '/home' : '/login',
      );
    } catch (e, st) {
      // Last-resort safety net: if anything goes wrong (e.g. the
      // router is gone, a provider throws synchronously, etc.) we
      // still navigate to /login so the user is never stuck.
      debugPrint('[Splash] boot error: $e\n$st');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Text(
                  'HelpDesk',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'E-Ticketing System',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms),
                const SizedBox(height: 64),
                // Loading indicator
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms),
                const SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.75),
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
                      Colors.white.withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.5),
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

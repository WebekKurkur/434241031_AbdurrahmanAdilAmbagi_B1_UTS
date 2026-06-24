// lib/presentation/widgets/auth_scaffold.dart
//
// Common scaffold for all three auth screens (login / register
// / forgot-password). Mirrors the Figma "AuthLayout" frame
// (node 8071:2, 388 × 842):
//
//   - solid surface background (reads as #F5F7FA in light mode,
//     #0F1115 in dark mode via `context.semantic.surface`)
//   - on phone (< 480 wide): edge-to-edge, 22.5 px h-padding
//   - on wide (≥ 480): 480 px max-width, 32 px h-padding
//   - 52.5 px top padding for breathing room
//   - bottom padding 30 px
//   - no rounded card / border / shadow (Option B, 2026-06-22)
//
// 2026-06-24: Now reads `context.semantic.surface` so it flips
// with `Theme.of(context).brightness` (Phase 3 → completed).

import 'package:flutter/material.dart';
import '../theme/app_semantic.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final Widget? topBar;
  final EdgeInsetsGeometry contentPadding;

  const AuthScaffold({
    super.key,
    required this.child,
    this.topBar,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Scaffold(
      backgroundColor: c.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 480;
          final double maxFormWidth = isWide ? 480 : double.infinity;
          final double horizontalPadding = isWide ? 32 : 22.5;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Container(
                  width: maxFormWidth,
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    52.5,
                    horizontalPadding,
                    30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (topBar != null) topBar!,
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Logo header used by login + register screens (Figma "Logo"
/// component, 37.5 × 37.5 blue rounded square + wordmark).
///
/// 2026-06-24: Wordmark + subtitle now read `context.semantic`
/// so they flip with dark mode. Brand blue stays fixed.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 37.5,
          height: 37.5,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB), // brand blue, fixed
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.headset_mic_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 7.5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Helpdesk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                letterSpacing: -0.16,
                height: 1.5,
              ),
            ),
            Text(
              'E-Ticketing System',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

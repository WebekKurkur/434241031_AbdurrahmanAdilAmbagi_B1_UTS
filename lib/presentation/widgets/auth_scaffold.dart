// lib/presentation/widgets/auth_scaffold.dart

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
      // 2026-06-25 fix: wrap the form in SafeArea(top: true,
      // bottom: false) so the Logo + back-link sit BELOW the
      // Android status-bar / cutout, not underneath it. Bottom
      // stays false because the `SingleChildScrollView` already
      // accounts for the keyboard + system-nav inset.
      body: SafeArea(
        top: true,
        bottom: false,
        child: LayoutBuilder(
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
                    // Top padding dropped from 52.5 → 22.5
                    // because SafeArea now supplies the status-bar
                    // inset; the 22.5 just gives breathing room
                    // between the back-link and the Logo.
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      22.5,
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
      ),
    );
  }
}

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

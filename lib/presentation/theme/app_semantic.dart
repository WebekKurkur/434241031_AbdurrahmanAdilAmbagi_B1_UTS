// lib/presentation/theme/app_semantic.dart
//
// 2026-06-24: Phase 1 of the theme refactor
// (ignore/todo-theme.md).
//
// Semantic color tokens used by the redesigned screens. Each
// token has a light + dark variant. Widgets read the right
// variant via the `BuildContext.semantic` extension below.
//
// `const` widgets that consume these tokens MUST drop `const`
// because the tokens are runtime-resolved (we need to know
// `Theme.of(context).brightness` first).
//
// Brand colors (purple #8b5cf6, blue #2563eb, green #10b981,
// amber #f59e0b, red #ef4444) are NOT defined here — they're
// semantic-by-design and stay fixed in both modes. Reach for
// them directly (`Color(0xFF2563EB)` etc.) when you need them.

import 'package:flutter/material.dart';

/// Raw semantic tokens. Mostly `Color(0x...)` constants so the
/// tokens file itself can be `const` even though the resolved
/// values are runtime-resolved through `BuildContext.semantic`.
class AppSemantic {
  AppSemantic._();

  // ---------------------------------------------------------------------------
  // Surface — page / scaffold background
  // ---------------------------------------------------------------------------
  static const Color surface = Color(0xFFF5F7FA); // light: #f5f7fa
  static const Color surfaceDark = Color(0xFF0F1115); // dark: #0f1115

  // ---------------------------------------------------------------------------
  // Surface card — cards / sheets / surfaces-on-surface
  // ---------------------------------------------------------------------------
  static const Color surfaceCard = Colors.white; // light
  static const Color surfaceCardDark = Color(0xFF1A1D24); // dark

  // ---------------------------------------------------------------------------
  // Surface frosted — frosted header / reply-bar bg (80% alpha)
  // ---------------------------------------------------------------------------
  static const Color surfaceFrosted = Color(0xCCF5F7FA); // light, 80% #f5f7fa
  static const Color surfaceFrostedDark =
      Color(0xCC0F1115); // dark, 80% #0f1115

  // ---------------------------------------------------------------------------
  // Border — borders + dividers + toggle-off track
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFFE5E7EB); // light: #e5e7eb
  static const Color borderDark = Color(0xFF2D323B); // dark: #2d323b

  // ---------------------------------------------------------------------------
  // Text — primary / secondary / hint
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF0F1115); // light
  static const Color textPrimaryDark = Color(0xFFF5F7FA); // dark

  static const Color textSecondary = Color(0xFF6B7280); // light
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // dark

  static const Color textHint = Color(0xFF94A3B8); // light
  static const Color textHintDark = Color(0xFF64748B); // dark

  // ---------------------------------------------------------------------------
  // Tint neutral — subtle icon-container / summary-chip bg
  // ---------------------------------------------------------------------------
  static const Color tintNeutral = Color(0xFFF1F4F8); // light: #f1f4f8
  static const Color tintNeutralDark = Color(0xFF1F2937); // dark

  // ---------------------------------------------------------------------------
  // Shadow — card shadow on dark surfaces uses a low-alpha
  // white instead of a low-alpha black so it shows on dark.
  // ---------------------------------------------------------------------------
  static const Color shadow = Color(0x0F0F1115); // light: rgba(15,17,21,0.06)
  static const Color shadowDark = Color(0x1AFFFFFF); // dark: rgba(255,255,255,0.10)
}

/// Bundle of semantic colors resolved for the current `Brightness`.
/// Reach for this through `context.semantic` rather than
/// instantiating it directly.
@immutable
class AppSemanticColors {
  final Color surface;
  final Color surfaceCard;
  final Color surfaceFrosted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color tintNeutral;
  final Color shadow;

  const AppSemanticColors({
    required this.surface,
    required this.surfaceCard,
    required this.surfaceFrosted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.tintNeutral,
    required this.shadow,
  });

  /// Light-mode bundle — pre-baked `const` so `context.semantic`
  /// in light mode adds zero allocation overhead.
  static const AppSemanticColors light = AppSemanticColors(
    surface: AppSemantic.surface,
    surfaceCard: AppSemantic.surfaceCard,
    surfaceFrosted: AppSemantic.surfaceFrosted,
    border: AppSemantic.border,
    textPrimary: AppSemantic.textPrimary,
    textSecondary: AppSemantic.textSecondary,
    textHint: AppSemantic.textHint,
    tintNeutral: AppSemantic.tintNeutral,
    shadow: AppSemantic.shadow,
  );

  /// Dark-mode bundle.
  static const AppSemanticColors dark = AppSemanticColors(
    surface: AppSemantic.surfaceDark,
    surfaceCard: AppSemantic.surfaceCardDark,
    surfaceFrosted: AppSemantic.surfaceFrostedDark,
    border: AppSemantic.borderDark,
    textPrimary: AppSemantic.textPrimaryDark,
    textSecondary: AppSemantic.textSecondaryDark,
    textHint: AppSemantic.textHintDark,
    tintNeutral: AppSemantic.tintNeutralDark,
    shadow: AppSemantic.shadowDark,
  );
}

/// `BuildContext.semantic` returns the right `AppSemanticColors`
/// bundle for the current `Theme.of(context).brightness`.
///
/// Usage:
///
/// ```dart
/// final c = context.semantic;
/// return Container(
///   color: c.surface,
///   child: Text(
///     'Hello',
///     style: TextStyle(color: c.textPrimary),
///   ),
/// );
/// ```
extension SemanticContext on BuildContext {
  AppSemanticColors get semantic {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppSemanticColors.dark : AppSemanticColors.light;
  }
}

// lib/presentation/providers/theme_provider.dart
//
// 2026-06-22: refactored from a `bool` toggle to a 3-state
// `ThemeMode` (light / dark / system) to support the
// "Appearance" pill in the redesigned profile screen, which
// cycles through all three values.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setMode(ThemeMode mode) {
    state = mode;
  }

  void cycle() {
    switch (state) {
      case ThemeMode.light:
        state = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        state = ThemeMode.system;
        break;
      case ThemeMode.system:
        state = ThemeMode.light;
        break;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Backward-compatible boolean view of the theme provider. Used
/// by `main.dart` to drive `MaterialApp.themeMode` indirectly
/// (it now reads the full `ThemeMode` via `themeProvider`).
final isDarkModeProvider = Provider<bool>((ref) {
  switch (ref.watch(themeProvider)) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
    case ThemeMode.system:
      return false;
  }
});

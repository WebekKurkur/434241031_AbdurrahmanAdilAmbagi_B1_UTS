// lib/presentation/providers/theme_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false);

  void toggle() {
    state = !state;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

final isDarkModeProvider = Provider((ref) {
  return ref.watch(themeProvider);
});

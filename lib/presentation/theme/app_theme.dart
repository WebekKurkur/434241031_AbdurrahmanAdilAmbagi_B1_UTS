// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1E88E5);
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryContainer = Color(0xFFBBDEFB);

  static const statusOpen = Color(0xFFEF5350);
  static const statusOpenBg = Color(0xFFFFEBEE);
  // "Assigned" = admin picked a helpdesk, work not yet started.
  // Indigo/violet to differentiate from the orange "in progress".
  static const statusAssigned = Color(0xFF6366F1);
  static const statusAssignedBg = Color(0xFFEEF2FF);
  static const statusInProgress = Color(0xFFFF9800);
  static const statusInProgressBg = Color(0xFFFFF3E0);
  // "Closed" replaces the old "done" — terminal state, ticket shut.
  static const statusClosed = Color(0xFF43A047);
  static const statusClosedBg = Color(0xFFE8F5E9);
  // Aliases kept so any existing call sites / docs that still
  // reference the old `statusDone` constants don't break. (Will
  // be removed in a later cleanup pass once we grep for orphans.)
  static const statusDone = statusClosed;
  static const statusDoneBg = statusClosedBg;

  static const surface = Color(0xFFF8FAFF);
  static const surfaceDark = Color(0xFF121926);
  static const cardDark = Color(0xFF1E293B);

  // Phase G3: semantic text + divider tokens so screens don't
  // repeat the same hex literal 60+ times.
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const dividerLight = Color(0xFFE8EDF5);
  static const dividerDark = Color(0xFF2D3F55);

  // Dark-mode variants: `surfaceSubtleDark` is the dark equivalent of
  // `0xFFF1F5FB` — a near-card-blue used for icons / pill bgs / etc.
  static const surfaceSubtleDark = Color(0xFF334155);
  static const surfaceSubtle = Color(0xFFF1F5FB);

  // Figma redesign (2026-06-22) tokens for the auth screens.
  // Login + register + forgot-password share the same palette.
  // Sourced from the Figma `AuthLayout` style guide.
  static const authBg = Color(0xFFF5F7FA);          // outer background
  static const authBorder = Color(0xFFE5E7EB);       // card border
  static const authShadow = Color(0x1F0F1115);      // 12% black, drop shadow
  static const authFieldFill = Color(0xFFFFFFFF);   // input background
  static const authFieldText = Color(0xFF0F1115);   // input text
  static const authHint = Color(0xFF6B7280);         // placeholder / muted
  static const authError = Color(0xFFEF4444);       // error banner
  static const authErrorBg = Color(0xFFFEF2F2);     // error banner bg
  static const authPrimary = Color(0xFF2563EB);     // primary action
  static const authPrimaryPressed = Color(0xFF1D4ED8);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF5), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIconColor: const Color(0xFF94A3B8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE8EDF5), thickness: 1),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2D3F55), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIconColor: const Color(0xFF64748B),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2D3F55), thickness: 1),
  );
}

Color getStatusColor(TicketStatus status) {
  switch (status) {
    case TicketStatus.open: return AppColors.statusOpen;
    case TicketStatus.assigned: return AppColors.statusAssigned;
    case TicketStatus.inProgress: return AppColors.statusInProgress;
    case TicketStatus.closed: return AppColors.statusClosed;
  }
}

Color getStatusBgColor(TicketStatus status) {
  switch (status) {
    case TicketStatus.open: return AppColors.statusOpenBg;
    case TicketStatus.assigned: return AppColors.statusAssignedBg;
    case TicketStatus.inProgress: return AppColors.statusInProgressBg;
    case TicketStatus.closed: return AppColors.statusClosedBg;
  }
}

String getStatusLabel(TicketStatus status) {
  switch (status) {
    case TicketStatus.open: return 'Open';
    case TicketStatus.assigned: return 'Assigned';
    case TicketStatus.inProgress: return 'In Progress';
    case TicketStatus.closed: return 'Closed';
  }
}

String getRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.user: return 'User';
    case UserRole.helpdesk: return 'Helpdesk';
    case UserRole.admin: return 'Admin';
  }
}

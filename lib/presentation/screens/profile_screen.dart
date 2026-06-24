// lib/presentation/screens/profile_screen.dart
//
// Redesign (2026-06-22) per Figma node 8071:165.
//
// 2026-06-24: Phase 8 of the theme refactor (ignore/todo-theme.md).
// Header, identity card, settings card, footer, sign-out, theme
// pill all read `context.semantic` so they flip with
// `Theme.of(context).brightness`. Brand colors stay fixed:
//   - purple #8B5CF6 avatar + role pill
//   - blue #2563EB user-management card
//   - red #EF4444 sign-out + dialog logout

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_semantic.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import 'notification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.login_rounded,
                  size: 64,
                  color: AppColors.authPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please login to continue',
                  style: TextStyle(fontSize: 16, color: c.textPrimary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Header(),
                    const SizedBox(height: 18.75),
                    _IdentityCard(user: user),
                    const SizedBox(height: 15),
                    _KpiBlock(user: user),
                    if (user.role == UserRole.admin) ...[
                      const SizedBox(height: 11.25),
                      const _UserManagementLink(),
                    ],
                    const SizedBox(height: 18.75),
                    const _SettingsCard(),
                    const SizedBox(height: 15),
                    const _SignOutButton(),
                    const SizedBox(height: 15),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header (8071:1499-1500)
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 22.5, 18.75, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.semantic.textPrimary,
            letterSpacing: -0.48,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Identity card (8071:1502-1515)
// ─────────────────────────────────────────────────────────────────

class _IdentityCard extends ConsumerWidget {
  final UserEntity user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    final initials = _initialsFromName(user.name);
    final roleLabel = getRoleLabel(user.role);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Container(
        padding: const EdgeInsets.all(19.75),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar (56 px circle, brand purple — fixed)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.authAvatarBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 21.28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Name / email / role pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5.625),
                  Row(
                    children: [
                      _RolePill(label: roleLabel),
                      const SizedBox(width: 7.5),
                      Flexible(
                        child: Text(
                          user.department,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                            height: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    // Role pill is brand-purple driven (low-alpha overlay of
    // the brand color). Stays fixed across modes.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 1.875),
      decoration: BoxDecoration(
        color: AppColors.authAvatarBg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(33554400),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.authAvatarBg,
          letterSpacing: 0.5,
          height: 1.5,
        ),
      ),
    );
  }
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ─────────────────────────────────────────────────────────────────
// KPI block (shared `KpiCardHero` + `KpiCardSmall` from
// `lib/presentation/widgets/kpi_card.dart`).
// ─────────────────────────────────────────────────────────────────

class _KpiBlock extends ConsumerWidget {
  final UserEntity user;
  const _KpiBlock({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(ticketStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.75),
          child: Column(
            children: [
              KpiCardHero(
                label: 'Total tickets',
                value: stats.total,
                icon: Icons.confirmation_number_rounded,
                tint: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 11.25),
              Row(
                children: [
                  Expanded(
                    child: KpiCardSmall(
                      label: 'Open',
                      value: stats.open,
                      icon: Icons.fiber_new_rounded,
                      tint: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 11.25),
                  Expanded(
                    child: KpiCardSmall(
                      label: 'In Progress',
                      value: stats.inProgress,
                      icon: Icons.autorenew_rounded,
                      tint: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11.25),
              Row(
                children: [
                  Expanded(
                    child: KpiCardSmall(
                      label: 'Assigned to me',
                      value: _assignedToMe(ref, user),
                      icon: Icons.assignment_ind_rounded,
                      tint: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 11.25),
                  Expanded(
                    child: KpiCardSmall(
                      label: 'Closed',
                      value: stats.closed,
                      icon: Icons.check_circle_outline_rounded,
                      tint: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.75, vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  int _assignedToMe(WidgetRef ref, UserEntity user) {
    final ticketsAsync = ref.read(userTicketsProvider);
    return ticketsAsync.maybeWhen(
      data: (tickets) => tickets
          .where((t) =>
              t.assignedTo != null &&
              t.assignedTo == user.name &&
              t.status != TicketStatus.closed)
          .length,
      orElse: () => 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// User Management link (Figma 8098:425) — admin-only blue button
// that opens `/admin/users`. Brand blue, fixed in both modes.
// ─────────────────────────────────────────────────────────────────

class _UserManagementLink extends StatelessWidget {
  const _UserManagementLink();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Material(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F1115),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container — white-translucent 33.75x33.75
                Container(
                  width: 33.75,
                  height: 33.75,
                  decoration: BoxDecoration(
                    color: const Color(0x2EFFFFFF), // ≈ rgba(255,255,255,0.18)
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11.25),
                // Title + subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      Opacity(
                        opacity: 0.75,
                        child: Text(
                          'Manage accounts & roles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Settings list (8071:1528-1580)
// ─────────────────────────────────────────────────────────────────

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    final themeMode = ref.watch(themeProvider);
    final themeLabel = _labelFor(themeMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _Row(
              iconData: Icons.brightness_6_rounded,
              label: 'Appearance',
              trailing: _ThemePill(
                label: themeLabel,
                onTap: () {
                  final next = _nextMode(themeMode);
                  ref.read(themeProvider.notifier).setMode(next);
                },
              ),
            ),
            const _InsetDivider(),
            _Row(
              iconData: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              ),
            ),
            const _InsetDivider(),
            _Row(
              iconData: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const _InsetDivider(),
            _Row(
              iconData: Icons.help_outline_rounded,
              label: 'Help & support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact support@helpdesk.app'),
                    duration: Duration(milliseconds: 1200),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
    }
  }

  ThemeMode _nextMode(ThemeMode current) {
    switch (current) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
      case ThemeMode.system:
        return ThemeMode.light;
    }
  }
}

class _Row extends StatelessWidget {
  final IconData iconData;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.iconData,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11.25),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.tintNeutral,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 16, color: c.textSecondary),
          ),
          const SizedBox(width: 11.25),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                height: 1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: c.textSecondary,
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(height: 1, color: context.semantic.border),
    );
  }
}

class _ThemePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ThemePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 12.25, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(33554400),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sign out (8071:1582-1588) — brand red, fixed in both modes.
// ─────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: SizedBox(
        height: 41.25,
        child: OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.zero,
            foregroundColor: AppColors.authError,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout_rounded, size: 16, color: AppColors.authError),
              SizedBox(width: 7.5),
              Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authError,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    bool busy = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (sbCtx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Logout'),
              content: const Text(
                  'Apakah Anda yakin ingin keluar dari aplikasi?'),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setLocal(() => busy = true);
                          try {
                            await ref
                                .read(currentUserProvider.notifier)
                                .logout();
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (_) => false);
                          } catch (e) {
                            if (!dialogCtx.mounted) return;
                            setLocal(() => busy = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal logout: $e'),
                                backgroundColor: AppColors.statusOpen,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusOpen,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Keluar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Center(
        child: Text(
          'Helpdesk v2.0 · Build 2026.06',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: context.semantic.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

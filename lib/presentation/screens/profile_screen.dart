// lib/presentation/screens/profile_screen.dart
//
// Redesign (2026-06-22) per Figma node 8071:165.
//
// Identity card (white, 1 px border, 15 px radius):
//   56 px purple avatar (#8b5cf6) + name (16 px Bold) + email
//   (12 px Regular) + role pill (light purple bg, 11 px Semi
//   Bold purple) + department (11 px Regular #6b7280).
//
// Stats row: 2 cards, 85 px tall, 15 px radius
//   - "Tickets opened" = total userTicketsProvider length
//   - "Resolved"       = count where status == closed
//
// Settings list (single white card, 15 px radius, 1 px border,
// 212 h):
//   - Appearance  + "Light" / "Dark" / "System" pill (cycles
//                   through `themeProvider` on tap)
//   - Notifications → push NotificationScreen
//   - Settings    → push /settings
//   - Help & support → snackbar placeholder
//   Dividers (1 px #e5e7eb) inset 56 px from left.
//
// Sign-out: outlined button, 41.25 px tall, 15 px radius, 1 px
// border, logout icon + "Sign out" 14 px Semi Bold #ef4444.
// Confirmation dialog preserved from the previous version.
//
// Footer: "Helpdesk v2.0 · Build 2026.06" 11 px Regular #6b7280.
//
// Bottom nav is owned by HomeScreen; this screen doesn't draw
// one. The "Profile" tab is highlighted when this screen is the
// current tab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import 'notification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.authBg,
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
                const Text(
                  'Please login to continue',
                  style: TextStyle(fontSize: 16),
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
      backgroundColor: AppColors.authBg,
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
                    _Header(),
                    const SizedBox(height: 18.75),
                    _IdentityCard(user: user),
                    const SizedBox(height: 15),
                    _KpiBlock(user: user),
                    const SizedBox(height: 18.75),
                    const _SettingsCard(),
                    const SizedBox(height: 15),
                    _SignOutButton(),
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
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18.75, 22.5, 18.75, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.authFieldText,
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
    final initials = _initialsFromName(user.name);
    final roleLabel = getRoleLabel(user.role);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Container(
        padding: const EdgeInsets.all(19.75),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.authBorder),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F1115),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authFieldText,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.authHint,
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.authHint,
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
//
// Layout: 1 hero card + 2x2 grid of small cards. Counts come
// from the role-scoped `ticketStatsProvider` and `userTicketsProvider`,
// matching the dashboard's KPI section so users see the same
// numbers across the app.
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
// Settings list (8071:1528-1580)
// ─────────────────────────────────────────────────────────────────

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeLabel = _labelFor(themeMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.authBorder),
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
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11.25),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 16, color: AppColors.authHint),
          ),
          const SizedBox(width: 11.25),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.authFieldText,
                height: 1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.authHint,
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
      child: Container(height: 1, color: AppColors.authBorder),
    );
  }
}

class _ThemePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ThemePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 12.25, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.authBorder),
          borderRadius: BorderRadius.circular(33554400),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.authHint,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sign out (8071:1582-1588)
// ─────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.75),
      child: SizedBox(
        height: 41.25,
        child: OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.authBorder),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.75),
      child: Center(
        child: Text(
          'Helpdesk v2.0 · Build 2026.06',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.authHint,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

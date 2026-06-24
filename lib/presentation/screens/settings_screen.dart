// lib/presentation/screens/settings_screen.dart
//
// Redesign (2026-06-22) per Figma node 8071:273.
//
// AppHeader (81 px tall, rgba(245,247,250,0.8) bg + 1 px
// #e5e7eb bottom border):
//   - 33.75 × 33.75 back button (negative-margin overflow)
//   - "Settings" 17 px Semi Bold #0f1115, letter-spacing -0.17
//
// Body: 4 section groups, pl/pr 18.75, pt 15, pb 37.5,
// gap 18.75 between groups. Each group has an UPPERCASE
// section title (11 px Semi Bold #6b7280, tracking 0.66,
// pl 3.75) + a single white card (15 px radius, 1 px border,
// inner padding 1).
//
//   APPEARANCE    Theme row + Light/Dark segmented control
//   NOTIFICATIONS Push notifications toggle + Email notifications toggle
//   SECURITY      Change password (Update link) + Two-factor (Enabled pill)
//   ABOUT         Version (v2.0.1) + Terms & Privacy (View link)
//
// Bottom nav is owned by HomeScreen; this screen doesn't draw
// one. The "Profile" tab is highlighted when this is reached
// from the profile screen's Settings row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
// In-memory notification prefs (replace with shared_preferences
// when real persistence is needed).
// ─────────────────────────────────────────────────────────────────

final pushNotificationsProvider = StateProvider<bool>((_) => true);
final emailNotificationsProvider = StateProvider<bool>((_) => false);

// ─────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 37.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 0),
                    _SectionLabel(label: 'Appearance'),
                    SizedBox(height: 7.5),
                    _ThemeCard(),
                    SizedBox(height: 18.75),
                    _SectionLabel(label: 'Notifications'),
                    SizedBox(height: 7.5),
                    _NotificationsCard(),
                    SizedBox(height: 18.75),
                    _SectionLabel(label: 'Security'),
                    SizedBox(height: 7.5),
                    _SecurityCard(),
                    SizedBox(height: 18.75),
                    _SectionLabel(label: 'About'),
                    SizedBox(height: 7.5),
                    _AboutCard(),
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
// AppHeader (8071:1621-1627)
// ─────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _AppHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,
      decoration: const BoxDecoration(
        color: Color(0xCCF5F7FA), // 80% #f5f7fa
        border: Border(
          bottom: BorderSide(color: AppColors.authBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18.75, 0, 18.75, 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button (33.75 × 33.75, negative-margin)
            SizedBox(
              width: 26.25,
              height: 33.75,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -7.5,
                    top: 0,
                    child: GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 33.75,
                        height: 33.75,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.authFieldText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11.25),
            const Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authFieldText,
                  letterSpacing: -0.17,
                  height: 1.3,
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
// Section label
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3.75),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.authHint,
          letterSpacing: 0.66,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reusable card chrome (15 px radius, 1 px border, inner clip)
// ─────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final List<Widget> children;
  final double? height;
  const _CardShell({required this.children, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.authBorder);
  }
}

// ─────────────────────────────────────────────────────────────────
// Appearance card — Theme row + Light/Dark segmented control
// ─────────────────────────────────────────────────────────────────

class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return _CardShell(
      height: 65.5,
      children: [
        _Row(
          title: 'Theme',
          subtitle: 'Sync with system, light, or dark',
          trailing: _SegmentedTheme(
            value: mode == ThemeMode.dark ? _ThemeChoice.dark : _ThemeChoice.light,
            onChanged: (choice) {
              final next = choice == _ThemeChoice.dark
                  ? ThemeMode.dark
                  : ThemeMode.light;
              ref.read(themeProvider.notifier).setMode(next);
            },
          ),
        ),
      ],
    );
  }
}

enum _ThemeChoice { light, dark }

class _SegmentedTheme extends StatelessWidget {
  final _ThemeChoice value;
  final ValueChanged<_ThemeChoice> onChanged;
  const _SegmentedTheme({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3.75),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            label: 'Light',
            selected: value == _ThemeChoice.light,
            onTap: () => onChanged(_ThemeChoice.light),
          ),
          const SizedBox(width: 3.75),
          _SegmentButton(
            label: 'Dark',
            selected: value == _ThemeChoice.dark,
            onTap: () => onChanged(_ThemeChoice.dark),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 26.25,
        padding: const EdgeInsets.symmetric(horizontal: 11.25),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0F0F1115),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.authFieldText : AppColors.authHint,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Notifications card — 2 toggle rows
// ─────────────────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushNotificationsProvider);
    final email = ref.watch(emailNotificationsProvider);

    return _CardShell(
      height: 130,
      children: [
        _Row(
          title: 'Push notifications',
          subtitle: 'Real-time ticket updates on this device',
          trailing: _Toggle(
            value: push,
            onChanged: (v) =>
                ref.read(pushNotificationsProvider.notifier).state = v,
          ),
        ),
        const _CardDivider(),
        _Row(
          title: 'Email notifications',
          subtitle: 'Daily digest sent to your inbox',
          trailing: _Toggle(
            value: email,
            onChanged: (v) =>
                ref.read(emailNotificationsProvider.notifier).state = v,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Security card — Change password + Two-factor
// ─────────────────────────────────────────────────────────────────

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Last updated 21 days ago" is computed from the
    // auth row's `updated_at` via `passwordUpdatedAtProvider`.
    // If `null` we render "Never set".
    final passwordUpdated = ref.watch(passwordUpdatedAtProvider);
    final subtitle = passwordUpdated == null
        ? 'Never set'
        : _relativeTime(passwordUpdated);

    return _CardShell(
      height: 130,
      children: [
        _Row(
          title: 'Change password',
          subtitle: subtitle,
          trailing: _LinkText(
            label: 'Update',
            onTap: () {
              // Push the forgot-password flow which doubles as
              // change-password (Supabase sends a reset email).
              Navigator.pushNamed(context, '/forgot-password');
            },
          ),
        ),
        const _CardDivider(),
        _Row(
          title: 'Two-factor auth',
          subtitle: 'Add an extra layer of security',
          trailing: const _StatusPill(
            label: 'Enabled',
            bg: Color(0x2410B981), // rgba(16,185,129,0.14)
            fg: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

String _relativeTime(DateTime when) {
  final days = DateTime.now().difference(when).inDays;
  if (days <= 0) return 'Updated today';
  if (days == 1) return 'Last updated 1 day ago';
  return 'Last updated $days days ago';
}

// ─────────────────────────────────────────────────────────────────
// About card — Version + Terms & Privacy
// ─────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      height: 90,
      children: [
        _Row(
          title: 'Version',
          trailing: const Text(
            'v2.0.1',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.authHint,
              height: 1.5,
            ),
          ),
        ),
        const _CardDivider(),
        _Row(
          title: 'Terms & Privacy',
          trailing: _LinkText(
            label: 'View',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening Terms & Privacy — coming soon'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Row primitive (15 px h-padding, 11.25 px v-padding)
// ─────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _Row({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.authFieldText,
                    height: 1.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.authHint,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Trailing widgets: toggle, status pill, link text
// ─────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const w = 37.5, h = 22.5, knob = 19.0;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: value
              ? AppColors.authPrimary
              : AppColors.authBorder,
          borderRadius: BorderRadius.circular(33554400),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: value ? (w - knob - 1.75) : 1.75,
              top: 1.75,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F0F1115),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 1.875),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(33554400),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.5,
        ),
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.authPrimary,
          height: 1.5,
        ),
      ),
    );
  }
}

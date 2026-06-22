// lib/presentation/screens/settings_screen.dart
//
// Phase G4: Settings screen — extracted from `profile_screen.dart`
// to give the user a dedicated page for app preferences (dark
// mode, language, help/about, account). Navigation entry point is
// the gear icon in the profile screen header.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionTitle(label: 'Tampilan', isDark: isDark),
          _InfoCard(
            isDark: isDark,
            children: [
              _DarkModeTile(isDark: isDark),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
              _SettingsItem(
                icon: Icons.language_rounded,
                label: 'Bahasa',
                trailing: const Text(
                  'Indonesia',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                isDark: isDark,
                onTap: () => _infoSnack(context, 'Pilihan bahasa — coming soon'),
              ),
            ],
          ),

          _SectionTitle(label: 'Akun', isDark: isDark),
          _InfoCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: Icons.lock_outline_rounded,
                label: 'Ganti Password',
                isDark: isDark,
                onTap: () =>
                    _infoSnack(context, 'Ganti Password — coming soon'),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notifikasi',
                isDark: isDark,
                onTap: () =>
                    _infoSnack(context, 'Preferensi notifikasi — coming soon'),
              ),
              if (user?.role == UserRole.admin) ...[
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
                _SettingsItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Kelola Pengguna',
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
              ],
            ],
          ),

          _SectionTitle(label: 'Tentang', isDark: isDark),
          _InfoCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: Icons.help_outline_rounded,
                label: 'Bantuan',
                isDark: isDark,
                onTap: () => _infoSnack(context, 'Bantuan — coming soon'),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight),
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                label: 'Versi Aplikasi',
                trailing: const Text(
                  '2.0.0',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _infoSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  final bool isDark;
  const _DarkModeTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceSubtleDark
                  : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema Gelap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isDark ? 'Mode Gelap Aktif' : 'Mode Terang Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionTitle({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _InfoCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? AppColors.dividerDark
                : AppColors.dividerLight),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceSubtleDark
              : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFB0BAC9),
          ),
      onTap: onTap,
    );
  }
}
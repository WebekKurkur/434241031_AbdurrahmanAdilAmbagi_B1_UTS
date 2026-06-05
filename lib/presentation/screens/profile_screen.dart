// lib/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allTickets = ref.watch(userTicketsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Please login to continue', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    Color roleColor;
    IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleColor = const Color(0xFF7B1FA2);
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case UserRole.helpdesk:
        roleColor = AppColors.primary;
        roleIcon = Icons.headset_mic_rounded;
        break;
      default:
        roleColor = const Color(0xFF00838F);
        roleIcon = Icons.person_rounded;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Header bg
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 16, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  roleColor.withValues(alpha: 0.7),
                                  roleColor,
                                ],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: roleColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(roleIcon, color: Colors.white, size: 42),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.statusDone,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 14, color: roleColor),
                            const SizedBox(width: 6),
                            Text(
                              getRoleLabel(user.role),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: allTickets.when(
                data: (tickets) {
                  final stats = (
                    total: tickets.length,
                    open: tickets
                        .where((t) => t.status == TicketStatus.open)
                        .length,
                    progress: tickets
                        .where((t) => t.status == TicketStatus.inProgress)
                        .length,
                    done: tickets
                        .where((t) => t.status == TicketStatus.done)
                        .length,
                  );
                  return Row(
                    children: [
                      _StatItem(
                        value: stats.total.toString(),
                        label: 'Total',
                        isDark: isDark,
                      ),
                      _divider(),
                      _StatItem(
                        value: stats.open.toString(),
                        label: 'Open',
                        color: AppColors.statusOpen,
                        isDark: isDark,
                      ),
                      _divider(),
                      _StatItem(
                        value: stats.progress.toString(),
                        label: 'Progress',
                        color: AppColors.statusInProgress,
                        isDark: isDark,
                      ),
                      _divider(),
                      _StatItem(
                        value: stats.done.toString(),
                        label: 'Selesai',
                        color: AppColors.statusDone,
                        isDark: isDark,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Info section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Informasi Akun', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      _ProfileItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Nama Lengkap',
                        value: user.name,
                        isDark: isDark,
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _ProfileItem(
                        icon: Icons.badge_outlined,
                        label: 'Username',
                        value: user.username,
                        isDark: isDark,
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _ProfileItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                        isDark: isDark,
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _ProfileItem(
                        icon: Icons.business_outlined,
                        label: 'Departemen',
                        value: user.department,
                        isDark: isDark,
                      ),
                    ],
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Settings section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Pengaturan', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                    children: [
                      // Dark mode toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5FB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
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
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    isDark ? 'Mode Gelap Aktif' : 'Mode Terang Aktif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isDark,
                              onChanged: (_) =>
                                  ref.read(themeProvider.notifier).toggle(),
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifikasi',
                        isDark: isDark,
                        onTap: () {},
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _SettingsItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Ganti Password',
                        isDark: isDark,
                        onTap: () {},
                      ),
                      Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2D3F55)
                              : const Color(0xFFE8EDF5)),
                      _SettingsItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Bantuan',
                        isDark: isDark,
                        onTap: () {},
                      ),
                    ],
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Logout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Logout'),
                      content: const Text(
                          'Apakah Anda yakin ingin keluar dari aplikasi?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(currentUserProvider.notifier).logout();
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (_) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusOpen,
                          ),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF5350)),
                label: const Text('Keluar',
                    style: TextStyle(color: Color(0xFFEF5350))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF5350)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE8EDF5),
      );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final bool isDark;

  const _StatItem(
      {required this.value,
      required this.label,
      this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3F55)
                  : const Color(0xFFE8EDF5)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color ??
                    (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? const Color(0xFF2D3F55)
                : const Color(0xFFE8EDF5)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ProfileItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsItem(
      {required this.icon,
      required this.label,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B)),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? const Color(0xFF475569) : const Color(0xFFB0BAC9)),
      onTap: onTap,
    );
  }
}

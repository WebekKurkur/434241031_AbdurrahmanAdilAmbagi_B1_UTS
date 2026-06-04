// lib/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 1500),
        () => mounted ? setState(() => _loading = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate (not just refresh) so a cold start with a
          // restored session always shows the latest data from
          // Supabase rather than a stale in-memory cache.
          ref.invalidate(allTicketsProvider);
          ref.invalidate(userTicketsProvider);
          ref.invalidate(ticketStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        getRoleLabel(user.role).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // Stats section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  'Ringkasan Tiket',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _loading
                  ? _buildShimmerStats()
                  : _buildStatsGrid(ref, isDark),
            ),

            // Quick actions (User only)
            if (user.role == UserRole.user) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Buat Tiket',
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateTicketScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.list_alt_rounded,
                          label: 'Lihat Tiket',
                          color: const Color(0xFF00838F),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.track_changes_rounded,
                          label: 'Tracking',
                          color: const Color(0xFFFF9800),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Recent tickets
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiket Terbaru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Lihat Semua',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerCard(),
                  childCount: 3,
                ),
              )
            else
              SliverToBoxAdapter(
                child: ref.watch(userTicketsProvider).when(
                  data: (tickets) {
                    if (tickets.isEmpty) {
                      return Column(
                        children: [
                          _EmptyState(
                            isUser: user.role == UserRole.user,
                          ),
                          const SizedBox(height: 12),
                          // Diagnostic banner so the user can see
                          // whether the DB actually has rows that
                          // RLS is filtering out.
                          _DbStatusBanner(
                            isDark: isDark,
                            role: user.role,
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: tickets.take(4).toList().asMap().entries.map((entry) {
                        return TicketCard(
                          ticket: entry.value,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(
                                ticketId: entry.value.id,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 100 * entry.key),
                                duration: 400.ms)
                            .slideX(begin: 0.05);
                      }).toList(),
                    );
                  },
                  loading: () => Column(
                    children: List.generate(3, (_) => const ShimmerCard()),
                  ),
                  error: (err, stack) =>
                      Center(child: Text('Error loading tickets: $err')),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: const [
          ShimmerStatCard(),
          ShimmerStatCard(),
          ShimmerStatCard(),
          ShimmerStatCard(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref, bool isDark) {
    return ref.watch(ticketStatsProvider).when(
      data: (stats) {
        final statsList = [
          {
            'label': 'Total Tiket',
            'value': stats.total,
            'icon': Icons.confirmation_number_rounded,
            'color': AppColors.primary,
            'bgColor': AppColors.primary.withValues(alpha: 0.1),
          },
          {
            'label': 'Open',
            'value': stats.open,
            'icon': Icons.fiber_new_rounded,
            'color': AppColors.statusOpen,
            'bgColor': AppColors.statusOpen.withValues(alpha: 0.1),
          },
          {
            'label': 'In Progress',
            'value': stats.inProgress,
            'icon': Icons.autorenew_rounded,
            'color': AppColors.statusInProgress,
            'bgColor': AppColors.statusInProgress.withValues(alpha: 0.1),
          },
          {
            'label': 'Selesai',
            'value': stats.done,
            'icon': Icons.check_circle_outline_rounded,
            'color': AppColors.statusDone,
            'bgColor': AppColors.statusDone.withValues(alpha: 0.1),
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: statsList.asMap().entries.map((entry) {
              final s = entry.value;
              return _StatCard(
                label: s['label'] as String,
                value: s['value'] as int,
                icon: s['icon'] as IconData,
                color: s['color'] as Color,
                bgColor: s['bgColor'] as Color,
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 * entry.key),
                      duration: 400.ms)
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0),
                      delay: Duration(milliseconds: 100 * entry.key));
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) =>
          Center(child: Text('Error loading stats: $err')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? const Color(0xFF2D3F55) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isUser;
  const _EmptyState({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada tiket',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
          if (isUser) ...[
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk membuat tiket baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Diagnostic banner shown when the role-aware ticket list is empty.
/// Reports the raw row count (under current RLS), the filtered count,
/// the user's role, and any error. This is the single best way to
/// tell whether "empty list" means "no data in DB" or "RLS is hiding
/// rows from this role".
class _DbStatusBanner extends ConsumerWidget {
  final bool isDark;
  final UserRole role;
  const _DbStatusBanner({required this.isDark, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(ticketDbStatusProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: status.when(
        loading: () => const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Memeriksa database…', style: TextStyle(fontSize: 12)),
          ],
        ),
        error: (err, _) => Text(
          'DB check error: $err',
          style: const TextStyle(fontSize: 11, color: Colors.red),
        ),
        data: (s) {
          if (s.errorMessage != null) {
            return Text(
              'DB error: ${s.errorMessage}',
              style: const TextStyle(fontSize: 11, color: Colors.red),
            );
          }
          final roleName = role == UserRole.admin
              ? 'admin (lihat semua)'
              : role == UserRole.helpdesk
                  ? 'helpdesk (assigned to you)'
                  : 'user (created by you)';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status DB',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Role aktif: $roleName\n'
                '• Baris tiket di DB (raw, lewat RLS): ${s.totalRows}\n'
                '• Baris setelah filter role: ${s.matchCount ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              if (s.totalRows > 0 && (s.matchCount ?? 0) == 0) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠ DB punya ${s.totalRows} tiket, tapi role-filter tidak '
                  'cocok. Kemungkinan nama di profiles ≠ created_by/assigned_to '
                  'pada tiket. Tarik untuk refresh.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFB45309),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

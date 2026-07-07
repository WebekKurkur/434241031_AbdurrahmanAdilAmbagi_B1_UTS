// lib/presentation/screens/dashboard_screen.dart
//
// Dashboard screen.
//
// Scaffold, header, headings, recent-activity, FAB, _IconChip,
// debug banner all now read `context.semantic` so they flip with
// `Theme.of(context).brightness`. Brand colors stay fixed:
//   - purple #8B5CF6 avatar
//   - blue #2563EB FAB + "View all" link
//   - tinted icon containers stay color-coded by KPI
// Behaviour preserved (currentUserProvider, userTicketsProvider,
// ticketStatsProvider, ticketInvalidatorProvider, _DbStatusBanner,
// pull-to-refresh, animations).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_semantic.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/shimmer_card.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import '../widgets/ticket_list_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  /// Optional callback for switching the parent `HomeScreen`'s
  /// bottom-nav tab. Wired up by `HomeScreen.build()` so the
  /// "View all" link + "Buat Tiket" / "Lihat Tiket" / "Tracking"
  /// quick actions jump to the right tab instead of opening a
  /// new route.
  final ValueChanged<int>? onSwitchToTab;

  const DashboardScreen({super.key, this.onSwitchToTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Show shimmer for the first ~1.2 s so the layout doesn't
    // jump from skeleton to data. The realtime stream will
    // already have pushed the first list by then.
    Future.delayed(const Duration(milliseconds: 1200),
        () => mounted ? setState(() => _loading = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_rounded,
                  size: 64, color: AppColors.primary),
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
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      // 2026-06-25 fix: top: true so the header sits below the
      // status bar on Android 11+; bottom: false because the
      // home-screen's own Scaffold already takes the
      // bottom-nav insets into account.
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allTicketsProvider);
            ref.invalidate(userTicketsProvider);
            ref.invalidate(ticketStatsProvider);
          },
          child: Stack(
            children: [
              // Main scrollable content. The FAB sits over this and
              // gets pushed up by the bottom padding (90 px).
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      _buildHeading(),
                      _buildKpiSection(user),
                      const SizedBox(height: 22.5),
                      _buildSectionHeader(),
                      _buildRecentActivity(user),
                    ],
                  ),
                ),
              ),
              // FAB anchored bottom-right (~80 px from bottom on
            // an 842-tall canvas). 45 px circle,
            // 12 px shadow at 6 % opacity.
            if (user.role == UserRole.user)
              Positioned(
                right: 19.75,
                bottom: 80,
                child: _Fab(onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateTicketScreen()),
                )),
              ),
          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────── Header ───────────────────────────

  Widget _buildHeader(UserEntity user) {
    final c = context.semantic;
    final greeting = _greeting();
    final firstName = user.name.split(' ').first;
    final initials = _initials(user.name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 18.75, 18.75, 0),
      child: Row(
        children: [
          // Avatar (40 px circle, solid `#8b5cf6`) — brand color
          // stays fixed in both modes.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 15.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11.25),
          // Greeting + name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$greeting,',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              Text(
                firstName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right cluster: search only (theme toggle lives on
          // profile + settings per the latest IA)
          _IconChip(
            icon: Icons.search_rounded,
            onTap: () => widget.onSwitchToTab?.call(1),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─────────────────────────── Heading ──────────────────────────

  Widget _buildHeading() {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 18.75, 18.75, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations overview',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.52,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Live snapshot of your team's ticket queue.",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
    );
  }

  // ─────────────────────────── KPI section ──────────────────────

  Widget _buildKpiSection(UserEntity user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 18.75, 18.75, 0),
      child: _loading
          ? _buildShimmerKpis()
          : _buildKpis(user),
    );
  }

  Widget _buildShimmerKpis() {
    return const Column(
      children: [
        ShimmerStatCard(),
        SizedBox(height: 11.25),
        Row(
          children: [
            Expanded(child: ShimmerStatCard()),
            SizedBox(width: 11.25),
            Expanded(child: ShimmerStatCard()),
          ],
        ),
        SizedBox(height: 11.25),
        Row(
          children: [
            Expanded(child: ShimmerStatCard()),
            SizedBox(width: 11.25),
            Expanded(child: ShimmerStatCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildKpis(UserEntity user) {
    final statsAsync = ref.watch(ticketStatsProvider);
    return statsAsync.when(
      data: (stats) {
        // Counts already filtered by role via `userTicketsProvider`.
        return Column(
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
                    value: _assignedToMe(user),
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
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
      },
      loading: () => _buildShimmerKpis(),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Error loading stats: $err',
              style: const TextStyle(fontSize: 12, color: Colors.red)),
        ),
      ),
    );
  }

  // For helpdesk + admin: tickets with assignedTo == me.
  // For user: 0 (regular users don't get assigned tickets).
  int _assignedToMe(UserEntity user) {
    final ticketsAsync = ref.read(userTicketsProvider);
    return ticketsAsync.maybeWhen(
      data: (tickets) => tickets
          .where((t) =>
              t.assignedTo != null && t.assignedTo == user.name &&
              t.status != TicketStatus.closed)
          .length,
      orElse: () => 0,
    );
  }

  // ─────────────────────────── Recent activity ──────────────────

  Widget _buildSectionHeader() {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 22.5, 18.75, 0),
      child: Row(
        children: [
          Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
              height: 1.35,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => widget.onSwitchToTab?.call(1),
            behavior: HitTestBehavior.opaque,
            child: const Text(
              'View all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.authPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(UserEntity user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 11.25, 18.75, 0),
      child: _loading
          ? Column(
              children: List.generate(3, (_) => const ShimmerCard()),
            )
          : ref.watch(userTicketsProvider).when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return Column(
                      children: [
                        _EmptyState(isUser: user.role == UserRole.user),
                        if (kDebugMode) ...[
                          const SizedBox(height: 12),
                          _DbStatusBanner(role: user.role),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: tickets.take(3).toList().asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                                bottom: entry.key == 2 ? 0 : 11.25),
                            child: TicketListCard(
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
                                    delay: Duration(
                                        milliseconds: 100 * entry.key),
                                    duration: 400.ms)
                                .slideX(begin: 0.05),
                          ),
                        ).toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(3, (_) => const ShimmerCard()),
                ),
                error: (err, _) => Center(
                    child: Text('Error loading tickets: $err',
                        style: const TextStyle(fontSize: 12))),
              ),
    );
  }

  // ─────────────────────────── Helpers ──────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────
// Sub-widgets (private to dashboard)
// ─────────────────────────────────────────────────────────────────

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 33.75,
        height: 33.75,
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 16, color: c.textHint),
      ),
    );
  }
}

// KPI cards (KpiCardHero, KpiCardSmall) and `_kpiDecoration`
// live in `lib/presentation/widgets/kpi_card.dart` so the
// profile screen can render the same KPI layout.

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.authPrimary,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F1115),
              blurRadius: 16,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isUser;
  const _EmptyState({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: c.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Belum ada tiket',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          if (isUser) ...[
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk membuat tiket baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
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
/// and the user's role. This is the single best way to tell
/// whether "empty list" means "no data in DB" or "RLS is hiding
/// rows from this role".
class _DbStatusBanner extends ConsumerWidget {
  final UserRole role;
  const _DbStatusBanner({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    final status = ref.watch(ticketDbStatusProvider);
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintNeutral,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
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
                  color: c.textSecondary,
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
                  color: c.textPrimary,
                  height: 1.5,
                ),
              ),
              if (s.totalRows > 0 && (s.matchCount ?? 0) == 0) ...[
                const SizedBox(height: 8),
                const Text(
                  '⚠ DB punya baris tiket, tapi role-filter tidak cocok. '
                  'Kemungkinan nama di profiles ≠ created_by/assigned_to '
                  'pada tiket. Tarik untuk refresh.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
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

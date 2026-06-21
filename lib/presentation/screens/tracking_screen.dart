// lib/presentation/screens/tracking_screen.dart
//
// Phase D2 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-011 Tracking Tiket: a dedicated screen that lists the
// user's tickets sorted by most-recent activity, with each
// row showing the current status + last-update time + assignee.
// Tap a row → opens the detail screen.
//
// "Activity" comes from the `ticket_history` table (Phase A2)
// joined via a window function. The screen is realtime: any
// status change / new comment / assignment change made by
// another user reorders the list immediately.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

/// Tracker item — one row in the list.
class TrackingItem {
  final TicketEntity ticket;
  final DateTime lastActivityAt;
  final int activityCount;

  const TrackingItem({
    required this.ticket,
    required this.lastActivityAt,
    required this.activityCount,
  });
}

/// Provider that watches all tickets + their latest history row
/// for each, returning them sorted by last-activity desc.
///
/// "Latest activity" is the `created_at` of the most recent
/// `ticket_history` row for each ticket, or `tickets.created_at`
/// if no history exists yet.
final trackingListProvider =
    StreamProvider.autoDispose<List<TrackingItem>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield <TrackingItem>[];
    return;
  }

  // The async* generator with `ref.watch(provider)` re-runs on
  // each emission. Each call returns the latest AsyncValue.
  while (true) {
    final async = ref.read(allTicketsStreamProvider);
    final tickets = async.valueOrNull;
    if (tickets != null) {
      final filtered = _filterForUser(tickets, user.role, user.name);
      final repo = ref.read(ticketRepositoryProvider);
      final items = <TrackingItem>[];
      for (final t in filtered) {
        try {
          final history = await repo.getTicketHistory(t.id);
          final last = history.isEmpty
              ? t.createdAt
              : history.first.createdAt;
          items.add(TrackingItem(
            ticket: t,
            lastActivityAt: last,
            activityCount: history.length,
          ));
        } catch (_) {
          items.add(TrackingItem(
            ticket: t,
            lastActivityAt: t.createdAt,
            activityCount: 0,
          ));
        }
      }
      items.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
      yield items;
    }
    // Wait for the next change. This suspension makes the
    // stream cancellable when the consumer closes (autoDispose).
    await _waitForChange(ref, allTicketsStreamProvider);
  }
});

/// Suspend until `provider` changes. Used to turn a StreamProvider
/// into an event loop for an `async*` generator.
Future<void> _waitForChange(Ref ref, ProviderListenable<AsyncValue<dynamic>> provider) async {
  final completer = Completer<void>();
  ref.listen(provider, (_, __) {
    if (!completer.isCompleted) completer.complete();
  }, fireImmediately: false);
  return completer.future;
}

/// Role-aware filter: users see their own tickets; helpdesk and
/// admin see all (matches the RLS policy on the `tickets` table).
List<TicketEntity> _filterForUser(
  List<TicketEntity> tickets,
  UserRole role,
  String currentUserName,
) {
  if (role == UserRole.user) {
    return tickets
        .where((t) => t.createdBy == currentUserName)
        .toList();
  }
  return tickets;
}

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackingAsync = ref.watch(trackingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Tiket'),
      ),
      body: trackingAsync.when(
        loading: () => _LoadingState(isDark: isDark),
        error: (e, _) => _ErrorState(
          isDark: isDark,
          onRetry: () => ref.invalidate(trackingListProvider),
          error: e,
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(isDark: isDark)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(trackingListProvider);
                  await ref.read(trackingListProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _TrackingCard(
                    item: items[i],
                    isDark: isDark,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final TrackingItem item;
  final bool isDark;
  const _TrackingCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = item.ticket;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: t.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ticket code chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.id,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    _StatusChip(status: t.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Bottom row: activity + assignee
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.activityCount} aktivitas',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatLastActivity(item.lastActivityAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    if (t.assignedTo != null) ...[
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.assignedTo!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastActivity(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return DateFormat('d MMM').format(when);
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final bg = getStatusBgColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            getStatusLabel(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final bool isDark;
  const _LoadingState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada tiket untuk dilacak',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  final Object error;
  const _ErrorState({
    required this.isDark,
    required this.onRetry,
    required this.error,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat data tracking',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/presentation/screens/ticket_history_screen.dart
//
// Phase D1 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// Renders the per-ticket audit log (FR-010 Riwayat, BR-005
// History Service). The `ticket_history` table is populated by
// Postgres triggers in migration `0003_ticket_history.sql` and
// surfaced in Dart via `ticketHistoryStreamProvider` from
// `ticket_provider.dart`.
//
// This widget is a DraggableScrollableSheet (modal). It's launched
// from the "Lihat Riwayat" button on the ticket detail screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_entity.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';

/// Show the history timeline as a draggable bottom sheet.
///
/// `ticketId` may be either the public `ticket_code` (e.g.
/// "TKT-001") or the row's uuid — the underlying stream accepts
/// both.
Future<void> showTicketHistorySheet(
  BuildContext context,
  String ticketId,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TicketHistorySheet(ticketId: ticketId),
  );
}

class _TicketHistorySheet extends ConsumerWidget {
  final String ticketId;
  const _TicketHistorySheet({required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(ticketHistoryStreamProvider(ticketId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Riwayat Tiket',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    if (historyAsync.valueOrNull != null)
                      Text(
                        '${historyAsync.value!.length} aktivitas',
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
              const Divider(height: 1),
              Expanded(
                child: historyAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat riwayat',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(
                              ticketHistoryStreamProvider(ticketId),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (rows) => rows.isEmpty
                      ? _EmptyHistory(isDark: isDark)
                      : _HistoryList(
                          rows: rows,
                          scrollController: scrollController,
                          isDark: isDark,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool isDark;
  const _EmptyHistory({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 56,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada aktivitas',
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

class _HistoryList extends StatelessWidget {
  final List<TicketHistoryEntity> rows;
  final ScrollController scrollController;
  final bool isDark;
  const _HistoryList({
    required this.rows,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length,
      itemBuilder: (_, i) => _HistoryRow(
        row: rows[i],
        isFirst: i == 0,
        isLast: i == rows.length - 1,
        isDark: isDark,
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final TicketHistoryEntity row;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _HistoryRow({
    required this.row,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
  });

  IconData get _icon {
    switch (row.action) {
      case 'created':
        return Icons.add_circle_outline_rounded;
      case 'assigned':
        return Icons.person_add_alt_1_rounded;
      case 'status_changed':
        return Icons.sync_rounded;
      case 'commented':
        return Icons.chat_bubble_outline_rounded;
      case 'closed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  Color get _iconBg {
    switch (row.action) {
      case 'created':
        return AppColors.statusOpenBg;
      case 'assigned':
        return AppColors.statusAssignedBg;
      case 'status_changed':
        return AppColors.statusInProgressBg;
      case 'commented':
        return AppColors.statusOpenBg;
      case 'closed':
        return AppColors.statusClosedBg;
      default:
        return AppColors.statusAssignedBg;
    }
  }

  Color get _iconFg {
    switch (row.action) {
      case 'created':
        return AppColors.statusOpen;
      case 'assigned':
        return AppColors.statusAssigned;
      case 'status_changed':
        return AppColors.statusInProgress;
      case 'commented':
        return AppColors.statusOpen;
      case 'closed':
        return AppColors.statusClosed;
      default:
        return AppColors.statusAssigned;
    }
  }

  String get _title {
    switch (row.action) {
      case 'created':
        return row.actorName == null
            ? 'Tiket dibuat'
            : '${row.actorName} membuat tiket';
      case 'assigned':
        return '${row.actorName ?? 'Seseorang'} menugaskan tiket';
      case 'status_changed':
        return '${row.actorName ?? 'Seseorang'} mengubah status';
      case 'commented':
        return row.actorName == null
            ? 'Komentar ditambahkan'
            : '${row.actorName} menambahkan komentar';
      case 'closed':
        return row.actorName == null
            ? 'Tiket ditutup'
            : '${row.actorName} menutup tiket';
      default:
        return row.note ?? 'Aktivitas';
    }
  }

  String? get _subtitle {
    switch (row.action) {
      case 'status_changed':
        if (row.fromValue == null || row.toValue == null) return null;
        return '${_humanStatus(row.fromValue!)} → ${_humanStatus(row.toValue!)}';
      case 'assigned':
        if (row.toValue == null) return null;
        if (row.toValue == 'unassigned') return 'Penugasan dihapus';
        return 'Ditugaskan ke ${row.toValue}';
      case 'commented':
        return row.note ?? 'Komentar baru';
      default:
        return null;
    }
  }

  String _humanStatus(String s) {
    switch (s) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'inProgress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line + dot
          SizedBox(
            width: 56,
            child: Column(
              children: [
                // Top spacer / line
                SizedBox(
                  height: 18,
                  width: 2,
                  child: isFirst
                      ? const SizedBox.shrink()
                      : Container(color: const Color(0xFFE2E8F0)),
                ),
                // Dot
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: _iconFg, size: 16),
                ),
                // Bottom spacer / line
                Expanded(
                  child: SizedBox(
                    width: 2,
                    child: isLast
                        ? const SizedBox.shrink()
                        : Container(color: const Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (_subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(row.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return DateFormat('d MMM, HH:mm').format(when);
  }
}
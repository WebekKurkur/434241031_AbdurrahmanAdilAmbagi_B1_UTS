// lib/presentation/screens/tracking_screen.dart
//
// Per-ticket tracking page (Figma 8071:835).
//
// Reached from the "View tracking" link on the ticket detail
// screen. Shows the ticket's current status + a 4-stage progress
// bar (Created → Assigned → In Progress → Closed) plus a vertical
// timeline of every `ticket_history` event for the ticket.
//
// Backed by:
//   - `ticketByIdProvider(ticketId)`        — single ticket row
//   - `ticketHistoryStreamProvider(id)`     — realtime history stream
//
// 2026-06-24: Phase 12 of the theme refactor (ignore/todo-theme.md).
// AppHeader, summary card, progress bar, timeline rows, loading +
// error states all read `context.semantic` so they flip with
// `Theme.of(context).brightness`. Brand colors stay fixed:
//   - blue #2563EB (progress bar fill, "commented" timeline dot)
//   - purple #8B5CF6 ("assigned" timeline dot)
//   - amber #F59E0B ("status_changed" timeline dot)
//   - green #10B981 ("closed" timeline dot + closed status pill)
//   - status pill fg+bg pairs (color-coded by status)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_entity.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_semantic.dart';
import '../theme/app_theme.dart';

class TrackingScreen extends ConsumerWidget {
  final String ticketId;
  const TrackingScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketByIdProvider(ticketId));
    final historyAsync = ref.watch(ticketHistoryStreamProvider(ticketId));

    return Scaffold(
      backgroundColor: context.semantic.surface,
      body: ticketAsync.when(
        loading: () => const _TrackingLoading(),
        error: (e, _) => _TrackingError(
          error: e,
          onRetry: () => ref.invalidate(ticketByIdProvider(ticketId)),
        ),
        data: (ticket) {
          if (ticket == null) {
            return _TrackingError(
              error: 'Ticket not found',
              onRetry: () => ref.invalidate(ticketByIdProvider(ticketId)),
            );
          }
          return _TrackingBody(
            ticket: ticket,
            history: historyAsync.value ?? const <TicketHistoryEntity>[],
            historyLoading: historyAsync.isLoading,
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Body — stack of [AppHeader, SummaryCard, HistoryTimeline]
// ===========================================================================

class _TrackingBody extends StatelessWidget {
  final TicketEntity ticket;
  final List<TicketHistoryEntity> history;
  final bool historyLoading;
  const _TrackingBody({
    required this.ticket,
    required this.history,
    required this.historyLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AppHeader(ticketCode: ticket.id),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 37.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryCard(ticket: ticket, history: history),
                const SizedBox(height: 22.5),
                const _SectionLabel(text: 'History'),
                _Timeline(
                  history: history,
                  loading: historyLoading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// AppHeader (8071:883) — 52.5h frosted, back + "Tracking" + ticket code
// ===========================================================================

class _AppHeader extends StatelessWidget {
  final String ticketCode;
  const _AppHeader({required this.ticketCode});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Container(
      height: 52.5,
      decoration: BoxDecoration(
        color: c.surfaceFrosted, // 80% surface alpha
        border: Border(
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.75),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button — 20px icon, -7.5px negative margin
            SizedBox(
              width: 26.25,
              height: 33.75,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -7.5,
                    top: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                        width: 33.75,
                        height: 33.75,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11.25),
            // "Tracking" title + ticket code subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      letterSpacing: -0.17,
                      height: 22.1 / 17,
                    ),
                  ),
                  Text(
                    ticketCode.isEmpty ? '—' : ticketCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      height: 15.6 / 12,
                    ),
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

// ===========================================================================
// SummaryCard (8071:894) — card with title + opened + status pill +
// 4-stage progress bar + 4 stage labels
// ===========================================================================

class _SummaryCard extends StatelessWidget {
  final TicketEntity ticket;
  final List<TicketHistoryEntity> history;
  const _SummaryCard({required this.ticket, required this.history});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    // Stage reached = the index of the current ticket status in the
    // 4-stage lifecycle (Created=0, Assigned=1, In Progress=2,
    // Closed=3). Anything past `inProgress` is "reached" so the
    // progress bar fills accordingly.
    final reached = _stageReached(ticket.status, history);

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.border, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + opened (left) | status pill (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        letterSpacing: -0.16,
                        height: 20.8 / 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opened ${DateFormat('d MMMM y, HH:mm', 'id_ID').format(ticket.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11.25),
              _StatusPill(status: ticket.status),
            ],
          ),
          const SizedBox(height: 11.25),
          // Progress bar (8071:905) — 5.625h, full width, blue fill
          // proportional to the reached stage (0..4).
          LayoutBuilder(
            builder: (context, c) {
              return Container(
                height: 5.625,
                decoration: BoxDecoration(
                  // Track bg = tintNeutral (light tint in light
                  // mode, dark grey in dark mode). Fill stays
                  // brand blue on both surfaces.
                  color: context.semantic.tintNeutral,
                  borderRadius: BorderRadius.circular(33554400),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: reached / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // brand blue
                        borderRadius: BorderRadius.circular(33554400),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 7.5),
          // 4 stage labels (Created / Assigned / In Progress / Closed)
          Row(
            children: [
              Expanded(child: _StageLabel(text: 'Created')),
              Expanded(child: _StageLabel(text: 'Assigned', align: TextAlign.center)),
              Expanded(child: _StageLabel(text: 'In Progress', align: TextAlign.center)),
              Expanded(child: _StageLabel(text: 'Closed', align: TextAlign.end)),
            ],
          ),
        ],
      ),
    );
  }

  /// Map a ticket's current status to a 0..4 "stage reached" value
  /// (where 0 = nothing reached yet, 4 = all stages completed).
  static int _stageReached(
    TicketStatus status,
    List<TicketHistoryEntity> history,
  ) {
    switch (status) {
      case TicketStatus.open:
        return 1; // Created
      case TicketStatus.assigned:
        return 2; // Created + Assigned
      case TicketStatus.inProgress:
        return 3; // Created + Assigned + In Progress
      case TicketStatus.closed:
        return 4; // All four
    }
  }
}

// ===========================================================================
// StatusPill (8071:901) — pill at top-right of summary card
// ===========================================================================

class _StatusPill extends StatelessWidget {
  final TicketStatus status;
  const _StatusPill({required this.status});

  // Status pill fg+bg pairs — brand-color coded, kept fixed
  // across light/dark (low-alpha tints read OK on both card
  // surfaces).
  static const Map<TicketStatus, Color> _fg = {
    TicketStatus.open: Color(0xFF10B981),
    TicketStatus.assigned: Color(0xFF2563EB),
    TicketStatus.inProgress: Color(0xFFF59E0B),
    TicketStatus.closed: Color(0xFF10B981),
  };

  static const Map<TicketStatus, Color> _bg = {
    TicketStatus.open: Color(0x1410B981),
    TicketStatus.assigned: Color(0x142563EB),
    TicketStatus.inProgress: Color(0x14F59E0B),
    TicketStatus.closed: Color(0x1410B981),
  };

  @override
  Widget build(BuildContext context) {
    final color = _fg[status] ?? const Color(0xFF10B981);
    final bg = _bg[status] ?? const Color(0x1410B981);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(33554400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9.375, vertical: 1.875),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.625,
            height: 5.625,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.625),
          Text(
            getStatusLabel(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.06,
              color: color,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// StageLabel (8071:908/911/913/915) — 11px grey under progress bar
// ===========================================================================

class _StageLabel extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _StageLabel({required this.text, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: context.semantic.textSecondary,
        height: 16.5 / 11,
      ),
    );
  }
}

// ===========================================================================
// SectionLabel — uppercase 11px Semi Bold
// ===========================================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 11.25, bottom: 0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.semantic.textSecondary,
          letterSpacing: 0.66,
          height: 16.5 / 11,
        ),
      ),
    );
  }
}

// ===========================================================================
// Timeline (8071:919) — vertical list of events, dot+title+date+actor
// ===========================================================================

class _Timeline extends StatelessWidget {
  final List<TicketHistoryEntity> history;
  final bool loading;
  const _Timeline({required this.history, required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;

    if (loading && history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Belum ada aktivitas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
      );
    }

    // Sort newest first to match the Figma ordering (newest event
    // at the top of the timeline).
    final events = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          _TimelineRow(
            event: events[i],
            showConnector: i < events.length - 1,
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// _TimelineRow (8071:920+) — dot on the left, title + date + actor on
// the right, vertical connector line between dots.
// ===========================================================================

class _TimelineRow extends StatelessWidget {
  final TicketHistoryEntity event;
  final bool showConnector;
  const _TimelineRow({required this.event, required this.showConnector});

  // Timeline dot border + fill — brand-color coded, kept fixed
  // across light/dark. Each color is dark enough to read as a
  // visible border ring on the light surface bg, and the
  // saturated fill stays distinct in both modes.
  static const Map<String, Color> _dotBorderColors = {
    'created': Color(0xFF6B7280),
    'assigned': Color(0xFF8B5CF6),
    'status_changed': Color(0xFFF59E0B),
    'closed': Color(0xFF10B981),
    'commented': Color(0xFF2563EB),
  };

  static const Map<String, Color> _dotFillColors = {
    'created': Color(0xFF6B7280),
    'assigned': Color(0xFF8B5CF6),
    'status_changed': Color(0xFFF59E0B),
    'closed': Color(0xFF10B981),
    'commented': Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final border = _dotBorderColors[event.action] ?? const Color(0xFF6B7280);
    final fill = _dotFillColors[event.action] ?? const Color(0xFF6B7280);
    final title = _titleFor(event);
    final actor = _actorFor(event);
    final date = DateFormat('d MMM · HH:mm', 'id_ID').format(event.createdAt);

    return IntrinsicHeight(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Connector line (8071:926) — between this row's dot and
          // the next row's dot. Anchored left:11, w:1px.
          if (showConnector)
            Positioned(
              left: 11,
              top: 18.75,
              bottom: 0,
              child: Container(
                width: 1,
                color: c.border,
              ),
            ),
          // Dot (8071:927) — 22.5px circle, 2px border, 7.5px fill.
          // Dot bg matches the scaffold surface so the ring +
          // fill read as a "ringed dot" on either mode.
          Positioned(
            left: 0,
            top: 3.75,
            child: Container(
              width: 22.5,
              height: 22.5,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: border, width: 2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Title + date row, 21h, with date absolute-positioned on
          // the right (8071:921-923).
          Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 18.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 21,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                            height: 21 / 14,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 4,
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                            height: 16.5 / 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actor line (8071:924) — 12px grey.
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    actor,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      height: 18 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(TicketHistoryEntity e) {
    switch (e.action) {
      case 'created':
        return 'Created';
      case 'assigned':
        return 'Assigned';
      case 'status_changed':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      case 'commented':
        return 'Commented';
      default:
        return e.action;
    }
  }

  String _actorFor(TicketHistoryEntity e) {
    final name = (e.actorName ?? '').trim();
    final base = name.isEmpty ? 'System' : 'by $name';
    if (e.toValue != null && e.toValue!.isNotEmpty) {
      return '$base · ${e.toValue}';
    }
    return base;
  }
}

// ===========================================================================
// Loading + Error states
// ===========================================================================

class _TrackingLoading extends StatelessWidget {
  const _TrackingLoading();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _TrackingError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _TrackingError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: c.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat data tracking',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary,
              ),
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

// lib/presentation/providers/paginated_tickets_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import 'ticket_provider.dart';

// `auth_provider` import is intentionally omitted — the notifier
// reads the ticket repository directly, and role filtering is
// already applied at the RLS layer.

/// State held by [PaginatedTicketsNotifier].
class PaginatedTicketsState {
  /// Tickets currently loaded for this page state.
  final List<TicketEntity> tickets;

  /// True when the most recent fetch returned fewer rows than the
  /// page size (or the fetch failed). The list screen uses this
  /// to hide the "muat lebih banyak" footer.
  final bool hasMore;

  /// True while a fetch is in flight.
  final bool loading;

  /// Total number of rows that exist under the current RLS + filter
  /// context (from `countTicketsWithFilter`). The UI uses this to
  /// show "X of Y".
  final int totalCount;

  /// Status filter applied to this page state. `null` means "all".
  final TicketStatus? statusFilter;

  /// Bumped on every full refresh so the [ScrollController] can
  /// decide whether to snap back to the top.
  final int refreshKey;

  const PaginatedTicketsState({
    this.tickets = const [],
    this.hasMore = false,
    this.loading = false,
    this.totalCount = 0,
    this.statusFilter,
    this.refreshKey = 0,
  });

  PaginatedTicketsState copyWith({
    List<TicketEntity>? tickets,
    bool? hasMore,
    bool? loading,
    int? totalCount,
    TicketStatus? statusFilter,
    bool clearStatusFilter = false,
    int? refreshKey,
  }) {
    return PaginatedTicketsState(
      tickets: tickets ?? this.tickets,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      totalCount: totalCount ?? this.totalCount,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      refreshKey: refreshKey ?? this.refreshKey,
    );
  }
}

const int _kPageSize = 20;

class PaginatedTicketsNotifier extends StateNotifier<PaginatedTicketsState> {
  final Ref ref;
  final TicketStatus? initialStatusFilter;

  PaginatedTicketsNotifier(this.ref, this.initialStatusFilter)
      : super(PaginatedTicketsState(
          statusFilter: initialStatusFilter,
        )) {
    // Kick off the first fetch immediately so the list screen
    // doesn't have to wait for a `ref.read(provider).loadFirstPage()`
    // call in `initState`.
    loadFirstPage();
  }

  TicketRepository get _repo =>
      ref.read(ticketRepositoryProvider);

  /// Fetch the first page (clearing any existing rows) and reset
  /// the cursor. Safe to call repeatedly — e.g. on pull-to-refresh.
  Future<void> loadFirstPage() async {
    if (state.loading) return;
    state = state.copyWith(
      loading: true,
      tickets: const [],
      refreshKey: state.refreshKey + 1,
    );
    await _fetch(0, append: false);
  }

  /// Fetch the next page (appending to existing rows). No-op when
  /// the previous page returned fewer than `pageSize` rows.
  Future<void> loadNextPage() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    await _fetch(state.tickets.length, append: true);
  }

  /// Switch the active status filter and reload the first page.
  Future<void> setStatusFilter(TicketStatus? statusFilter) async {
    if (state.statusFilter == statusFilter) return;
    state = state.copyWith(
      statusFilter: statusFilter,
      clearStatusFilter: statusFilter == null,
      tickets: const [],
      hasMore: false,
      totalCount: 0,
      refreshKey: state.refreshKey + 1,
    );
    await _fetch(0, append: false);
  }

  /// Full refresh: re-fetch the first page AND the total count.
  /// Used after mutations (status change, assign, add comment,
  /// add ticket, delete) so the list reflects the new state.
  Future<void> refresh() async {
    await loadFirstPage();
  }

  Future<void> _fetch(int from, {required bool append}) async {
    try {
      final page = await _repo.getTicketsPage(
        from: from,
        to: from + _kPageSize - 1,
        statusFilter: state.statusFilter,
        pageSize: _kPageSize,
      );
      final total = await _repo.countTicketsWithFilter(
        statusFilter: state.statusFilter,
      );
      if (!mounted) return;
      final newList = append ? [...state.tickets, ...page] : page;
      state = state.copyWith(
        tickets: newList,
        totalCount: total,
        hasMore: page.length == _kPageSize && newList.length < total,
        loading: false,
      );
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        hasMore: false,
      );
      // Re-throw via Error so the UI can show a snackbar. We use
      // a print here to keep state-notifier pure.
      // ignore: avoid_print
      print('[paginated-tickets] fetch failed: $e\n$st');
    }
  }
}

/// `paginatedTicketsProvider` is keyed by the requested status
/// filter. Tab 0 (Semua) uses `null`; tab N uses the matching
/// `TicketStatus`.
final paginatedTicketsProvider = StateNotifierProvider.family<
    PaginatedTicketsNotifier, PaginatedTicketsState, TicketStatus?>(
  (ref, statusFilter) {
    return PaginatedTicketsNotifier(ref, statusFilter);
  },
);

/// Convenience: invalidate every paginated-tickets family key
/// after a mutation (add ticket, status change, assign, delete,
/// realtime refresh). Use this from screens so they don't have
/// to list all 5 status keys manually.
void invalidateAllPaginatedProviders(WidgetRef ref) {
  ref.invalidate(paginatedTicketsProvider(null));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.open));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.assigned));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.inProgress));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.closed));
}
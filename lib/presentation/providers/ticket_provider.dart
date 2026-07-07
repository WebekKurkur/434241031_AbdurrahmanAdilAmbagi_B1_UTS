// lib/presentation/providers/ticket_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/storage_helper.dart';
import '../../core/network/supabase_providers.dart';
import '../../data/datasources/ticket_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/ticket/add_comment_usecase.dart';
import '../../domain/usecases/ticket/add_ticket_usecase.dart';
import '../../domain/usecases/ticket/assign_ticket_usecase.dart';
import '../../domain/usecases/ticket/delete_ticket_usecase.dart';
import '../../domain/usecases/ticket/get_tickets_usecase.dart';
import '../../domain/usecases/ticket/update_ticket_status_usecase.dart';
import '../../domain/usecases/ticket/upload_ticket_image_usecase.dart';
import 'auth_provider.dart';
import 'paginated_tickets_provider.dart';

// Data Sources
final ticketDataSourceProvider = Provider((ref) => TicketDataSource());

// Repositories
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final dataSource = ref.watch(ticketDataSourceProvider);
  final storage = ref.watch(storageHelperProvider);
  return TicketRepositoryImpl(dataSource, storage);
});

// Use Cases
final getTicketsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return GetTicketsUseCase(repository);
});

final addTicketUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return AddTicketUseCase(repository);
});

final updateTicketStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return UpdateTicketStatusUseCase(repository);
});

final assignTicketUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return AssignTicketUseCase(repository);
});

final deleteTicketUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return DeleteTicketUseCase(repository);
});

final addCommentUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return AddCommentUseCase(repository);
});

final uploadTicketImageUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return UploadTicketImageUseCase(repository);
});
// All Tickets
final allTicketsProvider = FutureProvider<List<TicketEntity>>((ref) async {
  final useCase = ref.watch(getTicketsUseCaseProvider);
  return await useCase();
});

/// Realtime stream of tickets. Built from a custom controller so
/// that the stream emits the *current* list of tickets on
/// subscription (i.e. an initial fetch) AND on every subsequent
/// Supabase realtime event. Without the initial emission, the
/// `ref.listen` in [ticketInvalidatorProvider] would never fire
/// until the first row changed — meaning stale data would sit on
/// screen after a cold start.
final allTicketsStreamProvider = StreamProvider<List<TicketEntity>>((ref) {
  final ds = ref.watch(ticketDataSourceProvider);

  late StreamController<List<TicketEntity>> controller;
  StreamSubscription<List<TicketEntity>>? realtimeSub;

  Future<void> emit() async {
    try {
      final tickets = await ds.getTickets();
      if (!controller.isClosed) controller.add(tickets);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  controller = StreamController<List<TicketEntity>>(
    onListen: () {
      // Initial fetch: push the current list immediately.
      emit();
      // Then subscribe to Supabase realtime and re-emit on every change.
      realtimeSub = ds.watchTickets().listen(
        (_) => emit(),
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
      );
    },
    onCancel: () {
      realtimeSub?.cancel();
      realtimeSub = null;
    },
  );

  ref.onDispose(() {
    realtimeSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

// Role-aware ticket filter. The semantics are:
//   user     \u2192 tickets they created (createdBy == currentUser.name)
//   helpdesk \u2192 tickets assigned to them (assignedTo == currentUser.name)
//   admin    \u2192 all tickets
//
// We match by the *name* field of the profile (the join's payload)
// because that is what `t.createdBy` / `t.assignedTo` contain.
final userTicketsProvider = FutureProvider<List<TicketEntity>>((ref) async {
  final tickets = await ref.watch(allTicketsProvider.future);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return [];
  switch (currentUser.role) {
    case UserRole.user:
      return tickets
          .where((t) => t.createdBy == currentUser.name)
          .toList();
    case UserRole.helpdesk:
      return tickets
          .where((t) => t.assignedTo == currentUser.name)
          .toList();
    case UserRole.admin:
      return tickets;
  }
});

/// Diagnostic: how many tickets the *current* session actually sees
/// from Supabase (after RLS). Used by the dashboard's "DB status"
/// banner so users can tell whether the empty list is "no tickets
/// in DB" vs "RLS is hiding rows from this role".
class TicketDbStatus {
  final int totalRows;        // raw count under current RLS
  final String? errorMessage; // null on success
  final int? matchCount;      // matches the role-aware filter
  const TicketDbStatus({
    required this.totalRows,
    this.errorMessage,
    this.matchCount,
  });
}

final ticketDbStatusProvider =
    FutureProvider<TicketDbStatus>((ref) async {
  final ds = ref.watch(ticketDataSourceProvider);
  try {
    // Raw count under current RLS (same SELECT the list uses, no joins)
    final raw = await ds.countTickets();
    // Role-aware filtered list
    final filtered = await ref.watch(userTicketsProvider.future);
    return TicketDbStatus(
      totalRows: raw,
      matchCount: filtered.length,
    );
  } catch (e) {
    return TicketDbStatus(totalRows: 0, errorMessage: '$e');
  }
});

// Ticket Stats
//
// 5 fields, matching SRS v2.0.0 §3.4 FR-009:
//   - total      — all tickets in the role-scoped view
//   - open       — newly created, no helpdesk assigned
//   - assigned   — admin picked a helpdesk, work not started
//   - inProgress — helpdesk is actively working
//   - closed     — terminal state
final ticketStatsProvider = FutureProvider((ref) async {
  final tickets = await ref.watch(userTicketsProvider.future);
  return (
    total: tickets.length,
    open: tickets.where((t) => t.status == TicketStatus.open).length,
    assigned: tickets.where((t) => t.status == TicketStatus.assigned).length,
    inProgress:
        tickets.where((t) => t.status == TicketStatus.inProgress).length,
    closed: tickets.where((t) => t.status == TicketStatus.closed).length,
  );
});

// Single Ticket
final ticketByIdProvider =
    FutureProvider.family<TicketEntity?, String>((ref, id) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return await repository.getTicketById(id);
});

/// Realtime stream of comments for one ticket, keyed by the public
/// `ticket_code` (e.g. "TKT-001") or the row uuid.
///
/// The underlying repository stream re-emits on every Supabase
/// `comments` table event, so the detail screen sees new comments
/// posted by other users without needing to pull-to-refresh.
///
/// Marked `autoDispose` so a closed detail screen cancels its
/// realtime subscription and frees the socket.
final commentsStreamProvider = StreamProvider.autoDispose
    .family<List<CommentEntity>, String>((ref, ticketId) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.watchComments(ticketId);
});

/// Realtime stream of the per-ticket audit log
/// (`ticket_history` table), keyed by the public `ticket_code`
/// or the row uuid.
///
/// Emits the current list on subscription AND on every history
/// row change. The `ticket_history` rows are inserted by Postgres
/// triggers in `0003_ticket_history.sql` (on ticket create /
/// status change / assignment change / comment), so the stream
/// is the canonical "live activity feed" for a ticket (FR-010
/// Riwayat, FR-011 Tracking, BR-005 History Service).
final ticketHistoryStreamProvider = StreamProvider.autoDispose
    .family<List<TicketHistoryEntity>, String>((ref, ticketId) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.watchTicketHistory(ticketId);
});

/// All helpdesk users (for the assign sheet). Refreshed on demand
/// via `ref.invalidate(helpdeskUsersProvider)`.
class HelpdeskUser {
  final String id;
  final String username;
  final String name;
  final String department;
  const HelpdeskUser({
    required this.id,
    required this.username,
    required this.name,
    required this.department,
  });
}

final helpdeskUsersProvider =
    FutureProvider<List<HelpdeskUser>>((ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final users = await repository.getHelpdeskUsers();
  return users
      .map((u) => HelpdeskUser(
            id: u.id,
            username: u.username,
            name: u.name,
            department: u.department,
          ))
      .toList();
});

/// Side-effect provider: when the Supabase auth state changes
/// (SIGN_IN on cold start, SIGN_OUT, etc.) this invalidates every
/// ticket-related provider so the UI re-fetches against the new
/// session's RLS context.
///
/// Watching this in `main.dart` or in the root widget is enough — it
/// has no value of its own.
final ticketInvalidatorProvider = Provider<void>((ref) {
  // 1. Auth state changes (cold-start session restore, sign-out).
  // Skip ticket-data invalidation while the user is signed out —
  // every refetch would be rejected by RLS anyway (no auth.uid),
  // and the throw path can race with the Navigator swap to
  // `/login` (causing a blank hitam frame on real Android
  // devices when the previous screen's `c.surface` remains
  // attached for one extra frame).
  ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, __) {
    final user = ref.read(currentUserProvider);
    if (user == null) return; // ← skip during / right after logout
    ref.invalidate(allTicketsProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(ticketStatsProvider);
    _invalidatePaginated(ref);
  });

  // 2. Realtime ticket events (new ticket created, status changed,
  //    assignment changed by another user/device). When Supabase
  //    fires an INSERT / UPDATE on the `tickets` table, the stream
  //    emits a non-null list and we refetch.
  ref.listen<AsyncValue<List<TicketEntity>>>(
    allTicketsStreamProvider,
    (prev, next) {
      // Skip when no user is signed in (logout window).
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      // Only invalidate when the stream actually produced data
      // (not on loading / error states).
      next.whenData((tickets) {
        ref.invalidate(allTicketsProvider);
        ref.invalidate(userTicketsProvider);
        ref.invalidate(ticketStatsProvider);
        _invalidatePaginated(ref);
      });
    },
  );
});

/// Phase G1 helper: refresh every paginated-tickets family key.
/// Each tab keeps its own page state, so we have to invalidate
/// all five (Semua / Open / Assigned / Progress / Closed).
void _invalidatePaginated(Ref ref) {
  ref.invalidate(paginatedTicketsProvider(null));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.open));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.assigned));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.inProgress));
  ref.invalidate(paginatedTicketsProvider(TicketStatus.closed));
}

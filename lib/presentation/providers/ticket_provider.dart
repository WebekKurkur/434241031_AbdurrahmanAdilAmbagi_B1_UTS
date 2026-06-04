// lib/presentation/providers/ticket_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_providers.dart';
import '../../data/datasources/ticket_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/ticket/add_comment_usecase.dart';
import '../../domain/usecases/ticket/add_ticket_usecase.dart';
import '../../domain/usecases/ticket/assign_ticket_usecase.dart';
import '../../domain/usecases/ticket/get_tickets_usecase.dart';
import '../../domain/usecases/ticket/update_ticket_status_usecase.dart';
import 'auth_provider.dart';

// Data Sources
final ticketDataSourceProvider = Provider((ref) => TicketDataSource());

// Repositories
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final dataSource = ref.watch(ticketDataSourceProvider);
  return TicketRepositoryImpl(dataSource);
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

final addCommentUseCaseProvider = Provider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return AddCommentUseCase(repository);
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
final ticketStatsProvider = FutureProvider((ref) async {
  final tickets = await ref.watch(userTicketsProvider.future);
  return (
    total: tickets.length,
    open: tickets.where((t) => t.status == TicketStatus.open).length,
    inProgress:
        tickets.where((t) => t.status == TicketStatus.inProgress).length,
    done: tickets.where((t) => t.status == TicketStatus.done).length,
  );
});

// Single Ticket
final ticketByIdProvider =
    FutureProvider.family<TicketEntity?, String>((ref, id) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return await repository.getTicketById(id);
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
  // 1. Auth state changes (cold-start session restore, sign-out)
  ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, __) {
    ref.invalidate(allTicketsProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(ticketStatsProvider);
  });

  // 2. Realtime ticket events (new ticket created, status changed,
  //    assignment changed by another user/device). When Supabase
  //    fires an INSERT / UPDATE on the `tickets` table, the stream
  //    emits a non-null list and we refetch.
  ref.listen<AsyncValue<List<TicketEntity>>>(
    allTicketsStreamProvider,
    (prev, next) {
      // Only invalidate when the stream actually produced data
      // (not on loading / error states).
      next.whenData((tickets) {
        ref.invalidate(allTicketsProvider);
        ref.invalidate(userTicketsProvider);
        ref.invalidate(ticketStatsProvider);
      });
    },
  );
});

// lib/presentation/providers/ticket_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// User-filtered Tickets
final userTicketsProvider = FutureProvider<List<TicketEntity>>((ref) async {
  final tickets = await ref.watch(allTicketsProvider.future);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return [];
  if (currentUser.role == UserRole.user) {
    return tickets.where((t) => t.createdBy == currentUser.name).toList();
  }
  return tickets;
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

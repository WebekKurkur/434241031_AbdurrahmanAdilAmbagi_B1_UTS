// lib/data/repositories/ticket_repository_impl.dart
//
// Bridges the domain layer to the Supabase TicketDataSource.

import 'dart:typed_data';

import '../../core/network/storage_helper.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/usecases/ticket/add_ticket_usecase.dart';
import '../datasources/ticket_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketDataSource dataSource;
  final StorageHelper storage;

  TicketRepositoryImpl(this.dataSource, this.storage);

  @override
  Future<List<TicketEntity>> getTickets() async {
    final models = await dataSource.getTickets();
    return models.cast<TicketEntity>();
  }

  @override
  Future<List<TicketEntity>> getTicketsPage({
    required int from,
    required int to,
    TicketStatus? statusFilter,
    int pageSize = 20,
  }) async {
    final models = await dataSource.getTicketsPage(
      from: from,
      to: to,
      statusFilter: statusFilter,
      pageSize: pageSize,
    );
    return models.cast<TicketEntity>();
  }

  @override
  Future<int> countTicketsWithFilter({TicketStatus? statusFilter}) async {
    return await dataSource.countTicketsWithFilter(
      statusFilter: statusFilter,
    );
  }

  @override
  Future<TicketEntity?> getTicketById(String id) async {
    return await dataSource.getTicketById(id);
  }

  @override
  Future<TicketEntity> addTicket(AddTicketParams params) async {
    // The data source regenerates `ticket_code` and `created_at`
    // server-side and uses `auth.uid()` for `created_by`, so we
    // only forward the four user-supplied fields.
    final model = await dataSource.addTicket(
      title: params.title,
      description: params.description,
      category: params.category,
      imageUrl: params.imageUrl,
    );
    return model;
  }

  @override
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    return await dataSource.updateTicketStatus(ticketId, status);
  }

  @override
  Future<void> assignTicket(String ticketId, String assignedTo) async {
    return await dataSource.assignTicket(ticketId, assignedTo);
  }

  @override
  Future<void> deleteTicket(String ticketUuid) async {
    return await dataSource.deleteTicket(ticketUuid);
  }

  /// Fetch helpdesk users for the assign sheet.
  @override
  Future<List<HelpdeskUserSummary>> getHelpdeskUsers() async {
    final rows = await dataSource.getHelpdeskUsers();
    return rows
        .map((r) => HelpdeskUserSummary(
              id: r['id'] as String,
              username: r['username'] as String? ?? '',
              name: r['name'] as String? ?? '',
              department: r['department'] as String? ?? '',
            ))
        .toList();
  }

  @override
  Future<void> addComment(String ticketId, String message) async {
    // The data source pulls `author_id` from `auth.uid()` server-
    // side; we deliberately do not pass a client-supplied author
    // or role here.
    await dataSource.addComment(ticketId, message);
  }

  @override
  Stream<List<CommentEntity>> watchComments(String ticketId) {
    // The data source yields `CommentModel` (a `CommentEntity`
    // subclass). The stream already handles the initial fetch
    // (re-emits the current list on every `comments` table
    // change) so the consumer doesn't need to seed it.
    return dataSource.watchComments(ticketId);
  }

  @override
  Future<List<TicketHistoryEntity>> getTicketHistory(String ticketId) async {
    final models = await dataSource.getTicketHistory(ticketId);
    return models.cast<TicketHistoryEntity>();
  }

  @override
  Stream<List<TicketHistoryEntity>> watchTicketHistory(String ticketId) {
    return dataSource.watchTicketHistory(ticketId);
  }

  @override
  Future<String> uploadTicketImage({
    required Uint8List bytes,
    required String fileName,
    required String subdir,
  }) async {
    // Pull the file extension from the picker's file name. Fall
    // back to `jpg` for the camera (the OS sometimes returns a
    // bare name like `image`).
    final dot = fileName.lastIndexOf('.');
    var ext = dot == -1 ? 'jpg' : fileName.substring(dot + 1).toLowerCase();
    if (ext.length > 4 || ext.isEmpty) ext = 'jpg';
    return await storage.uploadImage(
      bytes,
      folder: 'tickets',
      subdir: subdir,
      ext: ext,
    );
  }
}

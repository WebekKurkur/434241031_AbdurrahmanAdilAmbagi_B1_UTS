// lib/data/repositories/ticket_repository_impl.dart
//
// Bridges the domain layer to the Supabase TicketDataSource.

import 'dart:typed_data';

import '../../core/network/storage_helper.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
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
  Future<TicketEntity?> getTicketById(String id) async {
    return await dataSource.getTicketById(id);
  }

  @override
  Future<TicketEntity> addTicket(TicketEntity ticket) async {
    final model = await dataSource.addTicket(
      title: ticket.title,
      description: ticket.description,
      category: ticket.category,
      imageUrl: ticket.imageUrl,
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
  Future<void> addComment(
    String ticketId,
    String message,
    String author,
    UserRole role,
  ) async {
    return await dataSource.addComment(ticketId, message, author, role);
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

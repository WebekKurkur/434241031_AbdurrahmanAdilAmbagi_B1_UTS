// lib/providers/app_provider.dart
// DEPRECATED: Use presentation/providers with Riverpod instead
// This is a stub for backwards compatibility with old screen code

export '../presentation/providers/auth_provider.dart';
export '../presentation/providers/ticket_provider.dart';
export '../presentation/providers/theme_provider.dart';

import 'package:flutter/material.dart';
import '../domain/entities/ticket_entity.dart';
import '../domain/entities/user_entity.dart';

// TODO: Refactor ticket_detail_screen.dart and create_ticket_screen.dart to use Riverpod
// Stub AppProvider for backwards compatibility
@Deprecated('Use Riverpod providers from presentation/providers instead')
class AppProvider extends ChangeNotifier {
  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;

  void addComment(String ticketId, String message) {}
  void updateTicketStatus(String ticketId, TicketStatus status) {}
  void assignTicket(String ticketId, String assignedTo) {}
  void addTicket(TicketEntity ticket) {}
  TicketEntity? getTicketById(String id) => null;
}

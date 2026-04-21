// lib/providers/app_provider.dart

import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/dummy_data_service.dart';

class AppProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isDarkMode = false;
  List<Ticket> _tickets = [];
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;

  List<Ticket> get userTickets {
    if (_currentUser == null) return [];
    if (_currentUser!.role == UserRole.user) {
      return _tickets
          .where((t) => t.createdBy == _currentUser!.name)
          .toList();
    }
    return _tickets;
  }

  int get totalTickets => userTickets.length;
  int get openTickets =>
      userTickets.where((t) => t.status == TicketStatus.open).length;
  int get inProgressTickets =>
      userTickets.where((t) => t.status == TicketStatus.inProgress).length;
  int get doneTickets =>
      userTickets.where((t) => t.status == TicketStatus.done).length;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final user = DummyDataService.authenticate(username);
    if (user != null && password == 'password') {
      _currentUser = user;
      _tickets = DummyDataService.generateDummyTickets();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    _tickets = [];
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void addTicket(Ticket ticket) {
    _tickets.insert(0, ticket);
    notifyListeners();
  }

  void updateTicketStatus(String ticketId, TicketStatus status) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  void assignTicket(String ticketId, String assignedTo) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(assignedTo: assignedTo);
      notifyListeners();
    }
  }

  void addComment(String ticketId, String message) {
    if (_currentUser == null) return;
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final newComment = Comment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        author: _currentUser!.name,
        message: message,
        createdAt: DateTime.now(),
        role: _currentUser!.role,
      );
      final updatedComments = [..._tickets[idx].comments, newComment];
      _tickets[idx] = _tickets[idx].copyWith(comments: updatedComments);
      notifyListeners();
    }
  }

  Ticket? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

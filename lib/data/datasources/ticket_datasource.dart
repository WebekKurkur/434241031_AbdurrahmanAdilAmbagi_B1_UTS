// lib/data/datasources/ticket_datasource.dart

import '../../domain/entities/user_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../models/ticket_model.dart';

class TicketDataSource {
  final List<TicketModel> _tickets = [];

  TicketDataSource() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    _tickets.addAll([
      TicketModel(
        id: 'TKT-001',
        title: 'Laptop tidak bisa menyala',
        description:
            'Laptop saya tiba-tiba mati dan tidak bisa dinyalakan kembali. Sudah mencoba tekan tombol power beberapa kali namun tidak ada respon sama sekali. Lampu indikator juga tidak menyala.',
        status: TicketStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        createdBy: 'Ahmad Rizki',
        assignedTo: 'Budi Santoso',
        category: 'Hardware',
        imageUrl: 'https://picsum.photos/seed/laptop/400/300',
        comments: [
          CommentModel(
            id: 'c1',
            author: 'Ahmad Rizki',
            message: 'Sudah coba charge dulu tapi tetap tidak mau nyala.',
            createdAt:
                DateTime.now().subtract(const Duration(days: 2, hours: 2)),
            role: UserRole.user,
          ),
          CommentModel(
            id: 'c2',
            author: 'Budi Santoso',
            message:
                'Terima kasih laporannya. Tim kami sedang investigasi. Mohon bawa laptop ke IT room besok pagi.',
            createdAt:
                DateTime.now().subtract(const Duration(days: 1, hours: 10)),
            role: UserRole.helpdesk,
          ),
        ],
      ),
      TicketModel(
        id: 'TKT-002',
        title: 'Email tidak bisa login',
        description:
            'Tidak bisa masuk ke email kantor sejak hari ini pagi. Sudah coba reset password tapi tetap tidak bisa. Pesan error: "Authentication failed".',
        status: TicketStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        createdBy: 'Ahmad Rizki',
        category: 'Software',
        imageUrl: 'https://picsum.photos/seed/email/400/300',
        comments: [],
      ),
      TicketModel(
        id: 'TKT-003',
        title: 'Printer di lantai 3 rusak',
        description:
            'Printer Canon di lantai 3 dekat ruang rapat tidak bisa print. Muncul pesan "Paper Jam" padahal kertas sudah dikeluarkan semua.',
        status: TicketStatus.done,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'Ahmad Rizki',
        assignedTo: 'Budi Santoso',
        category: 'Hardware',
        imageUrl: 'https://picsum.photos/seed/printer/400/300',
        comments: [
          CommentModel(
            id: 'c3',
            author: 'Budi Santoso',
            message: 'Sudah diperbaiki. Ada sisa kertas yang tersangkut di dalam.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            role: UserRole.helpdesk,
          ),
          CommentModel(
            id: 'c4',
            author: 'Ahmad Rizki',
            message: 'Terima kasih, sudah bisa digunakan kembali!',
            createdAt:
                DateTime.now().subtract(const Duration(days: 3, hours: 22)),
            role: UserRole.user,
          ),
        ],
      ),
      TicketModel(
        id: 'TKT-004',
        title: 'VPN tidak bisa connect',
        description:
            'Sejak kemarin VPN kantor tidak bisa terkoneksi. Sudah reinstall aplikasi VPN namun masih error. Error code: 0x800070570.',
        status: TicketStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'Ahmad Rizki',
        category: 'Network',
        comments: [],
      ),
      TicketModel(
        id: 'TKT-005',
        title: 'Monitor berkedip-kedip',
        description:
            'Monitor di meja kerja saya sering berkedip dan kadang layar menjadi hitam selama beberapa detik.',
        status: TicketStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'Ahmad Rizki',
        assignedTo: 'Budi Santoso',
        category: 'Hardware',
        imageUrl: 'https://picsum.photos/seed/monitor/400/300',
        comments: [
          CommentModel(
            id: 'c5',
            author: 'Budi Santoso',
            message:
                'Sedang dalam pengecekan kabel display port. Kemungkinan perlu penggantian kabel.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            role: UserRole.helpdesk,
          ),
        ],
      ),
      TicketModel(
        id: 'TKT-006',
        title: 'Software akuntansi error',
        description:
            'Aplikasi MYOB tidak bisa dibuka. Muncul pesan runtime error setiap kali mencoba membuka program.',
        status: TicketStatus.done,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        createdBy: 'Ahmad Rizki',
        assignedTo: 'Budi Santoso',
        category: 'Software',
        comments: [
          CommentModel(
            id: 'c6',
            author: 'Budi Santoso',
            message: 'Sudah dilakukan reinstall dan update. Silakan dicoba kembali.',
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
            role: UserRole.helpdesk,
          ),
        ],
      ),
    ]);
  }

  Future<List<TicketModel>> getTickets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _tickets;
  }

  Future<TicketModel?> getTicketById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTicket(TicketModel ticket) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tickets.insert(0, ticket);
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(status: status);
    }
  }

  Future<void> assignTicket(String ticketId, String assignedTo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(assignedTo: assignedTo);
    }
  }

  Future<void> addComment(String ticketId, CommentModel comment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final updatedComments = [..._tickets[index].comments, comment];
      _tickets[index] = _tickets[index].copyWith(comments: updatedComments.cast<CommentModel>());
    }
  }
}

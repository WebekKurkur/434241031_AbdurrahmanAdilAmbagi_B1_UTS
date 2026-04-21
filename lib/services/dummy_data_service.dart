// lib/services/dummy_data_service.dart

import '../models/ticket_model.dart';

class DummyDataService {
  static final List<AppUser> users = [
    AppUser(
      id: 'u1',
      name: 'Ahmad Rizki',
      username: 'user',
      email: 'ahmad.rizki@email.com',
      role: UserRole.user,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      department: 'Finance',
    ),
    AppUser(
      id: 'u2',
      name: 'Budi Santoso',
      username: 'helpdesk',
      email: 'budi.santoso@email.com',
      role: UserRole.helpdesk,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      department: 'IT Support',
    ),
    AppUser(
      id: 'u3',
      name: 'Citra Dewi',
      username: 'admin',
      email: 'citra.dewi@email.com',
      role: UserRole.admin,
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      department: 'IT Management',
    ),
  ];

  static AppUser? authenticate(String username) {
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  static List<Ticket> generateDummyTickets() {
    return [
      Ticket(
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
          Comment(
            id: 'c1',
            author: 'Ahmad Rizki',
            message: 'Sudah coba charge dulu tapi tetap tidak mau nyala.',
            createdAt:
                DateTime.now().subtract(const Duration(days: 2, hours: 2)),
            role: UserRole.user,
          ),
          Comment(
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
      Ticket(
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
      Ticket(
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
          Comment(
            id: 'c3',
            author: 'Budi Santoso',
            message: 'Sudah diperbaiki. Ada sisa kertas yang tersangkut di dalam.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            role: UserRole.helpdesk,
          ),
          Comment(
            id: 'c4',
            author: 'Ahmad Rizki',
            message: 'Terima kasih, sudah bisa digunakan kembali!',
            createdAt:
                DateTime.now().subtract(const Duration(days: 3, hours: 22)),
            role: UserRole.user,
          ),
        ],
      ),
      Ticket(
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
      Ticket(
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
          Comment(
            id: 'c5',
            author: 'Budi Santoso',
            message:
                'Sedang dalam pengecekan kabel display port. Kemungkinan perlu penggantian kabel.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            role: UserRole.helpdesk,
          ),
        ],
      ),
      Ticket(
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
          Comment(
            id: 'c6',
            author: 'Budi Santoso',
            message: 'Sudah dilakukan reinstall dan update. Silakan dicoba kembali.',
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
            role: UserRole.helpdesk,
          ),
        ],
      ),
    ];
  }
}

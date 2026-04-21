// lib/screens/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendComment(AppProvider provider) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    provider.addComment(widget.ticketId, text);
    _commentController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showStatusSheet(
      BuildContext context, Ticket ticket, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Status',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ...TicketStatus.values.map((status) {
                final isSelected = ticket.status == status;
                return ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(getStatusLabel(status),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.updateTicketStatus(ticket.id, status);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAssignSheet(
      BuildContext context, Ticket ticket, AppProvider provider) {
    final helpdeskUsers = ['Budi Santoso', 'Dewi Rahayu', 'Eko Prasetyo'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign ke',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ...helpdeskUsers.map((name) {
                final isSelected = ticket.assignedTo == name;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(name),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.assignTicket(ticket.id, name);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final ticket = provider.getTicketById(widget.ticketId);
    final user = provider.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage =
        user.role == UserRole.admin || user.role == UserRole.helpdesk;

    if (ticket == null) {
      return const Scaffold(
          body: Center(child: Text('Tiket tidak ditemukan')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.id),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'status') {
                  _showStatusSheet(context, ticket, provider);
                } else if (v == 'assign') {
                  _showAssignSheet(context, ticket, provider);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(Icons.update_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Update Status'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'assign',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Assign Tiket'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Image if available
                if (ticket.imageUrl != null)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEEF2F8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        ticket.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey.withOpacity(0.4), size: 40),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                // Ticket info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(status: ticket.status),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ticket.category,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Info grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2D3F55)
                                : const Color(0xFFE8EDF5),
                          ),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Dibuat oleh',
                                value: ticket.createdBy),
                            const Divider(height: 16),
                            _InfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'Tanggal',
                              value: DateFormat('dd MMMM yyyy, HH:mm')
                                  .format(ticket.createdAt),
                            ),
                            if (ticket.assignedTo != null) ...[
                              const Divider(height: 16),
                              _InfoRow(
                                icon: Icons.headset_mic_outlined,
                                label: 'Ditangani oleh',
                                value: ticket.assignedTo!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // Comments section
                if (ticket.comments.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Komentar (${ticket.comments.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...ticket.comments.asMap().entries.map((e) {
                    return _CommentBubble(
                      comment: e.value,
                      isCurrentUser: e.value.author == user.name,
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 100 * e.key),
                            duration: 300.ms);
                  }),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: Colors.grey.withOpacity(0.35)),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada komentar',
                            style: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2D3F55)
                      : const Color(0xFFE8EDF5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Tulis komentar...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(provider),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _sendComment(provider),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isCurrentUser;
  final bool isDark;

  const _CommentBubble({
    required this.comment,
    required this.isCurrentUser,
    required this.isDark,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF7B1FA2);
      case UserRole.helpdesk:
        return AppColors.primary;
      case UserRole.user:
        return const Color(0xFF00838F);
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.helpdesk:
        return 'Helpdesk';
      case UserRole.user:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(comment.role);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64 : 16,
        4,
        isCurrentUser ? 16 : 64,
        4,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getRoleLabel(comment.role),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                comment.author,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.primary
                  : isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5FB),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
              ),
            ),
            child: Text(
              comment.message,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isCurrentUser
                    ? Colors.white
                    : isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DateFormat('HH:mm, dd MMM').format(comment.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

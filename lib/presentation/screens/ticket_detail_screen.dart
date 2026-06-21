// lib/presentation/screens/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/ticket/add_comment_usecase.dart';
import '../../domain/usecases/ticket/assign_ticket_usecase.dart';
import '../../domain/usecases/ticket/update_ticket_status_usecase.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(addCommentUseCaseProvider)(
        AddCommentParams(
          ticketId: widget.ticketId,
          message: text,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal kirim komentar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // The comment count on the ticket cards in `ticket_list_screen.dart`
    // is read from `TicketEntity.comments.length` on the cached list
    // (`userTicketsProvider` / `allTicketsProvider`). Even though the
    // realtime `commentsStreamProvider` auto-emits on the INSERT and
    // re-renders the comment bubbles inside this screen, the parent
    // ticket list doesn't know about it — so we still need to refetch
    // the list and stats so the count badge next to the chat icon
    // updates immediately. (Without this, the count only updates
    // after a logout/login or a manual pull-to-refresh.)
    ref.invalidate(allTicketsProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(ticketStatsProvider);
    ref.invalidate(ticketByIdProvider(widget.ticketId));

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

  void _showStatusSheet(BuildContext context, TicketEntity ticket) {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // prevent tap-outside during the call
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool busy = false;
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            final isDark = Theme.of(innerContext).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Update Status',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const Spacer(),
                      if (busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...TicketStatus.values.map((status) {
                    final isSelected = ticket.status == status;
                    return ListTile(
                      enabled: !busy,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(getStatusLabel(status),
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: busy
                          ? null
                          : () async {
                              setSheetState(() => busy = true);
                              try {
                                await ref
                                    .read(updateTicketStatusUseCaseProvider)(
                                  UpdateTicketStatusParams(
                                    ticketId: ticket.id,
                                    status: status,
                                  ),
                                );
                                ref.invalidate(allTicketsProvider);
                                ref.invalidate(userTicketsProvider);
                                ref.invalidate(ticketStatsProvider);
                                ref.invalidate(
                                    ticketByIdProvider(ticket.id));
                                if (!mounted) return;
                                Navigator.pop(sheetContext);
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => busy = false);
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal update status: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignSheet(BuildContext context, TicketEntity ticket) {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // prevent tap-outside during the call
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Local busy state for the sheet. We use a StatefulBuilder
        // so the spinner is visible while the assign is in flight
        // (otherwise the user just sees a frozen sheet and thinks
        // the app is "buffering").
        bool busy = false;
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            final isDark = Theme.of(innerContext).brightness == Brightness.dark;
            final helpdeskAsync = ref.watch(helpdeskUsersProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Assign ke',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const Spacer(),
                      if (busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  helpdeskAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada user helpdesk',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: users.map((u) {
                          // `ticket.assignedTo` is the join's name field
                          // (e.g. "Budi Santoso"). Match by name OR by id
                          // in case the join ever changes.
                          final isSelected = ticket.assignedTo == u.name ||
                              ticket.assignedTo == u.username;
                          return ListTile(
                            enabled: !busy,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                u.name.isNotEmpty ? u.name[0] : '?',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(u.name),
                            subtitle: u.department.isNotEmpty
                                ? Text(
                                    u.department,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: AppColors.primary)
                                : null,
                            onTap: busy
                                ? null
                                : () async {
                                    setSheetState(() => busy = true);
                                    try {
                                      await ref
                                          .read(assignTicketUseCaseProvider)(
                                        AssignTicketParams(
                                          ticketId: ticket.id,
                                          // Pass the public `name`. The
                                          // data source resolves it to a
                                          // uuid before writing.
                                          assignedTo: u.name,
                                        ),
                                      );
                                      ref.invalidate(allTicketsProvider);
                                      ref.invalidate(userTicketsProvider);
                                      ref.invalidate(ticketStatsProvider);
                                      ref.invalidate(
                                          ticketByIdProvider(ticket.id));
                                      ref.invalidate(helpdeskUsersProvider);
                                      if (!mounted) return;
                                      Navigator.pop(sheetContext);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Tiket di-assign ke ${u.name}'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } catch (e) {
                                      // Reset the busy flag so the user
                                      // can try again.
                                      if (sheetContext.mounted) {
                                        setSheetState(() => busy = false);
                                      }
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Gagal assign: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Gagal memuat helpdesk: $err',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => ref.invalidate(helpdeskUsersProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cancel button: always visible (unless a tap is in
                  // flight) so the user can back out of the sheet
                  // without picking a helpdesk user. The bottom-sheet
                  // default is `isDismissible: true` for tap-outside,
                  // but a dedicated button is more discoverable.
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: busy ? null : () => Navigator.pop(sheetContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketByIdProvider(widget.ticketId));
    final commentsAsync =
        ref.watch(commentsStreamProvider(widget.ticketId));
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login kembali')),
      );
    }

    return ticketAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 56, color: Colors.red.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat tiket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(ticketByIdProvider(widget.ticketId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (ticket) {
        if (ticket == null) {
          return const Scaffold(
            body: Center(child: Text('Tiket tidak ditemukan')),
          );
        }

        // Role gating (per spec):
        //   * Update Status  → admin + helpdesk
        //   * Assign         → admin only
        // The DB enforces the same rules in a BEFORE UPDATE trigger
        // (see migration `0004_role_based_updates.sql`).
        final canChangeStatus =
            user.role == UserRole.admin || user.role == UserRole.helpdesk;
        final canAssign = user.role == UserRole.admin;
        final canManage = canChangeStatus || canAssign;

        // Read comments from the realtime stream so new
        // comments posted by other users appear live. While
        // the stream is still loading, fall back to the
        // comments that came with the initial ticket fetch.
        final liveComments = commentsAsync.valueOrNull;
        final comments = liveComments ?? ticket.comments;

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
                  _showStatusSheet(context, ticket);
                } else if (v == 'assign') {
                  _showAssignSheet(context, ticket);
                }
              },
              itemBuilder: (_) => [
                if (canChangeStatus)
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
                if (canAssign)
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
                              color: Colors.grey.withValues(alpha: 0.4), size: 40),
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
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                //
                // Reads from the realtime stream declared in
                // `data:` (see above) so new comments posted by
                // other users appear live.
                if (comments.isNotEmpty) ...[
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
                          'Komentar (${comments.length})',
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
                  ...comments.asMap().entries.map((e) {
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
                              color: Colors.grey.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada komentar',
                            style: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
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
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _sendComment(),
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
      },
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
  final CommentEntity comment;
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
                    color: roleColor.withValues(alpha: 0.1),
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

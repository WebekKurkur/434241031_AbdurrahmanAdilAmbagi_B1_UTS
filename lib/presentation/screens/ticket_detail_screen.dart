// lib/presentation/screens/ticket_detail_screen.dart
//
// Ticket detail — Figma `8071:543` direct port (2026-06-24).
//
// Visual spec is taken **only** from the Figma design context
// (no redesign-main doc). Layout, sizes, colors, and typography
// follow the React+Tailwind source node-by-node; behaviour
// (realtime comments, history, send, manage sheet) is preserved
// from the legacy implementation.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/ticket/add_comment_usecase.dart';
import '../../domain/usecases/ticket/assign_ticket_usecase.dart';
import '../../domain/usecases/ticket/update_ticket_status_usecase.dart';
import '../providers/auth_provider.dart';
import '../providers/paginated_tickets_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import 'tracking_screen.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(commentsStreamProvider(widget.ticketId));
      ref.read(ticketHistoryStreamProvider(widget.ticketId));
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Send comment
  // ---------------------------------------------------------------------------

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(addCommentUseCaseProvider)(
        AddCommentParams(ticketId: widget.ticketId, message: text),
      );
      ref.invalidate(allTicketsProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(ticketStatsProvider);
      invalidateAllPaginatedProviders(ref);
      ref.invalidate(ticketByIdProvider(widget.ticketId));

      _commentController.clear();
      _inputFocus.unfocus();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal kirim komentar: $e'),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Status / assign / delete (admin + helpdesk)
  // ---------------------------------------------------------------------------

  Future<void> _openStatusSheet(TicketEntity ticket) async {
    if (!canManageTicket(ref.read(currentUserProvider)?.role)) return;
    final next = await showModalBottomSheet<TicketStatus>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StatusSheet(current: ticket.status),
    );
    if (next == null || next == ticket.status || !mounted) return;
    try {
      await ref.read(updateTicketStatusUseCaseProvider)(
        UpdateTicketStatusParams(ticketId: ticket.id, status: next),
      );
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(allTicketsProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(ticketStatsProvider);
      invalidateAllPaginatedProviders(ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ubah status: $e'),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openAssignSheet(TicketEntity ticket) async {
    if (!canManageTicket(ref.read(currentUserProvider)?.role)) return;
    final helpdesk = await ref.read(helpdeskUsersProvider.future);
    if (!mounted) return;
    final next = await showModalBottomSheet<HelpdeskUser>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignSheet(
        users: helpdesk,
        currentName: ticket.assignedTo,
      ),
    );
    if (next == null || next.name == ticket.assignedTo || !mounted) return;
    try {
      await ref.read(assignTicketUseCaseProvider)(
        AssignTicketParams(ticketId: ticket.id, assignedTo: next.id),
      );
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(allTicketsProvider);
      ref.invalidate(userTicketsProvider);
      invalidateAllPaginatedProviders(ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal assign: $e'),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(TicketEntity ticket) async {
    if (!canManageTicket(ref.read(currentUserProvider)?.role)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tiket?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan. Tiket dan seluruh '
          'riwayat akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.authError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(deleteTicketUseCaseProvider)(ticket.id);
      ref.invalidate(allTicketsProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(ticketStatsProvider);
      invalidateAllPaginatedProviders(ref);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal hapus: $e'),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openManageSheet(TicketEntity ticket) async {
    final role = ref.read(currentUserProvider)?.role;
    if (!canManageTicket(role)) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageSheet(
        role: role,
        onStatus: () {
          Navigator.pop(ctx);
          _openStatusSheet(ticket);
        },
        onAssign: () {
          Navigator.pop(ctx);
          _openAssignSheet(ticket);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(ticket);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketByIdProvider(widget.ticketId));
    final commentsAsync = ref.watch(commentsStreamProvider(widget.ticketId));
    final historyAsync = ref.watch(ticketHistoryStreamProvider(widget.ticketId));
    final me = ref.watch(currentUserProvider);
    final canManage = canManageTicket(me?.role);

    return Scaffold(
      backgroundColor: AppColors.authBg,
      resizeToAvoidBottomInset: true,
      body: ticketAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (e, _) => _ErrorScaffold(
          message: 'Gagal memuat tiket: $e',
          onRetry: () => ref.invalidate(ticketByIdProvider(widget.ticketId)),
        ),
        data: (ticket) {
          if (ticket == null) {
            return const _ErrorScaffold(
              message: 'Tiket tidak ditemukan',
              onRetry: null,
            );
          }
          final requesterName = ticket.createdBy.isEmpty
              ? 'Unknown'
              : ticket.createdBy;
          final assigneeName = ticket.assignedTo;
          final historyCount = historyAsync.maybeWhen(
            data: (list) => list.length,
            orElse: () => 0,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18.75, 96, 18.75, 100),
                  children: [
                    _StatusRow(
                      status: ticket.status,
                      category: ticket.category,
                      canManage: canManage,
                      onManage: () => _openManageSheet(ticket),
                    ),
                    const SizedBox(height: 7.5),
                    _Title(text: ticket.title),
                    const SizedBox(height: 6),
                    _CreatedLine(date: ticket.createdAt),
                    const SizedBox(height: 15),
                    _PersonCards(
                      requesterName: requesterName,
                      assigneeName: assigneeName,
                    ),
                    const SizedBox(height: 11.25),
                    _AttachmentsCard(
                      imageUrl: ticket.imageUrl,
                    ),
                    const SizedBox(height: 15),
                    _DescriptionCard(text: ticket.description),
                    const SizedBox(height: 11.25),
                    _TrackingLink(
                      eventCount: historyCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackingScreen(ticketId: widget.ticketId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18.75),
                    _CommentsSection(
                      comments: commentsAsync.value ?? const [],
                      currentRole: me?.role,
                    ),
                  ].animate(interval: 40.ms).fadeIn(),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _AppHeader(
                    ticketCode: ticket.id,
                    category: ticket.category,
                    canManage: canManage,
                    onMore: () => _openManageSheet(ticket),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _ReplyBar(
                    controller: _commentController,
                    focusNode: _inputFocus,
                    sending: _sending,
                    onSend: _sendComment,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool canManageTicket(UserRole? role) =>
    role == UserRole.admin || role == UserRole.helpdesk;

// ===========================================================================
// AppHeader — 81 px frosted, back 20px icon, TKT-001 + category, theme toggle
// ===========================================================================

class _AppHeader extends ConsumerWidget {
  final String ticketCode;
  final String category;
  final bool canManage;
  final VoidCallback onMore;
  const _AppHeader({
    required this.ticketCode,
    required this.category,
    required this.canManage,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Container(
      height: 81,
      decoration: const BoxDecoration(
        color: Color(0xCCF5F7FA), // 80% #f5f7fa
        border: Border(
          bottom: BorderSide(color: AppColors.authBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.75),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button — 20px icon, -7.5px negative margin (8071:600)
            SizedBox(
              width: 26.25,
              height: 33.75,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -7.5,
                    top: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                        width: 33.75,
                        height: 33.75,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: Color(0xFF0F1115),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11.25),
            // Title + subtitle (8071:604)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticketCode.isEmpty ? 'Ticket' : ticketCode,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1115),
                      letterSpacing: -0.17,
                      height: 22.1 / 17,
                    ),
                  ),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 15.6 / 12,
                    ),
                  ),
                ],
              ),
            ),
            // Theme toggle (8071:609)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => ref.read(themeProvider.notifier).cycle(),
              child: Container(
                width: 33.75,
                height: 33.75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.authBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 16,
                  color: const Color(0xFF0F1115),
                ),
              ),
            ),
            // 3-dots menu — only shown for admin / helpdesk.
            // Opens the manage sheet (Update status, Assign to,
            // Delete ticket — gated by role inside the sheet).
            if (canManage) ...[
              const SizedBox(width: 7.5),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onMore,
                child: Container(
                  width: 33.75,
                  height: 33.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.authBorder,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: Color(0xFF0F1115),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Status row — pill (8071:614) + priority dot (8071:617)
// ===========================================================================

class _StatusRow extends StatelessWidget {
  final TicketStatus status;
  final String category;
  final bool canManage;
  final VoidCallback onManage;

  const _StatusRow({
    required this.status,
    required this.category,
    required this.canManage,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = _statusColors(status);
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(33554400),
          onTap: canManage ? onManage : null,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(33554400),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 9.375,
              vertical: 1.875,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.625,
                  height: 5.625,
                  decoration: BoxDecoration(
                    color: fg,
                    borderRadius: BorderRadius.circular(33554400),
                  ),
                ),
                const SizedBox(width: 5.625),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: -0.06,
                    height: 18 / 12,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded, size: 12, color: fg),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 7.5),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7.5,
                height: 7.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5.625),
              Flexible(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 18 / 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (String, Color, Color) _statusColors(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return ('Open', AppColors.statusOpen, AppColors.statusOpenBg);
      case TicketStatus.assigned:
        return ('Assigned', AppColors.statusAssigned, AppColors.statusAssignedBg);
      case TicketStatus.inProgress:
        return (
          'In Progress',
          AppColors.statusInProgress,
          AppColors.statusInProgressBg
        );
      case TicketStatus.closed:
        return ('Closed', AppColors.statusClosed, AppColors.statusClosedBg);
    }
  }
}

// ===========================================================================
// Title + created line
// ===========================================================================

class _Title extends StatelessWidget {
  final String text;
  const _Title({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F1115),
        letterSpacing: -0.44,
        height: 28.6 / 22,
      ),
    );
  }
}

class _CreatedLine extends StatelessWidget {
  final DateTime date;
  const _CreatedLine({required this.date});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM y, HH:mm', 'id_ID');
    return Text(
      fmt.format(date),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF6B7280),
        height: 18 / 12,
      ),
    );
  }
}

// ===========================================================================
// Person cards (8071:626, 8071:634) — fixed 60.5h, 166.625w each
// ===========================================================================

class _PersonCards extends StatelessWidget {
  final String requesterName;
  final String? assigneeName;
  const _PersonCards({required this.requesterName, required this.assigneeName});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight + stretch makes both cards share the
    // tallest intrinsic height. Letting the row auto-size
    // (instead of fixed `height: 60.5`) eliminates the 2px
    // bottom overflow that comes from line-box rounding.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PersonCard(
            label: 'Requester',
            name: requesterName,
            avatarColor: const Color(0xFF8B5CF6),
            isAssigned: true,
          ),
          const SizedBox(width: 11.25),
          _PersonCard(
            label: 'Assignee',
            name: assigneeName ?? 'Unassigned',
            avatarColor: assigneeName == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFF2563EB),
            isAssigned: false,
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String label;
  final String name;
  final Color avatarColor;
  final bool isAssigned; // determines avatar position (left)
  const _PersonCard({
    required this.label,
    required this.name,
    required this.avatarColor,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.authBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 12.16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 18.24 / 12.16,
                ),
              ),
            ),
            const SizedBox(width: 11.25),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 16.5 / 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1115),
                      height: 19.5 / 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String s) {
    if (s.isEmpty || s == 'Unassigned') return '–';
    final parts = s.trim().split(RegExp(r'\s+|@'));
    if (parts.length >= 2) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    return s.substring(0, 1).toUpperCase();
  }
}

// ===========================================================================
// Attachments card (8071:643) — 15px radius, fixed 295h, 240h image area
// ===========================================================================

class _AttachmentsCard extends StatelessWidget {
  final String? imageUrl;
  const _AttachmentsCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      height: 295,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Attachments'),
          // Figma places the 7.5px inner top-spacing on the image
          // wrapper (8071:646 `pt-[7.5px]`), not as a free gap
          // between the label and the image — so we apply it via
          // the image's own top padding rather than a SizedBox
          // (which previously added an extra ~7.5px on top of the
          // line-box leading of the label, causing ~2.5px bottom
          // overflow inside the 295h card).
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 7.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 231.5,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _AttachmentRow(),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 7.5),
              child: _AttachmentRow(),
            ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 231.5,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10.375),
          Container(
            width: 33.75,
            height: 33.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 11.25),
          const Expanded(
            child: Text(
              'picture',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F1115),
                height: 19.5 / 13,
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

// ===========================================================================
// Description card (8071:659) — 15px radius
// ===========================================================================

class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Description'),
          const SizedBox(height: 7.5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F1115),
              height: 22.4 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// View tracking link (8071:665) — 15px radius
// ===========================================================================

class _TrackingLink extends StatelessWidget {
  final int eventCount;
  final VoidCallback onTap;
  const _TrackingLink({required this.eventCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.authBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 33.75,
                  height: 33.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.route_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 11.25),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View tracking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1115),
                        height: 21 / 14,
                      ),
                    ),
                    Text(
                      '$eventCount event${eventCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Text(
              '›',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
                height: 27 / 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Section label — uppercase 11px, 0.66 tracking
// ===========================================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.66,
        height: 16.5 / 11,
      ),
    );
  }
}

// ===========================================================================
// Comments section (8071:679) — chat-bubble layout, fixed 301.25 × 118.25
// ===========================================================================

class _CommentsSection extends StatelessWidget {
  final List<CommentEntity> comments;
  final UserRole? currentRole;
  const _CommentsSection({required this.comments, required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(text: 'Comments'),
        const SizedBox(height: 7.5),
        if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.authBorder, width: 1),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(height: 6),
                Text(
                  'Belum ada komentar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        else
          for (final c in comments) ...[
            SizedBox(
              width: double.infinity,
              child: _CommentBubble(
                comment: c,
                currentRole: currentRole,
              ),
            ),
            const SizedBox(height: 11.25),
          ],
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final CommentEntity comment;
  final UserRole? currentRole;
  const _CommentBubble({required this.comment, required this.currentRole});

  /// Right-side bubble (outgoing) when the comment was posted
  /// by the same role as the current viewer. Left-side bubble
  /// (incoming) for everyone else.
  ///
  /// Examples:
  ///   - Viewer is `helpdesk` → helpdesk comments go right,
  ///     user/admin comments go left.
  ///   - Viewer is `admin` → admin comments go right, user/
  ///     helpdesk comments go left.
  ///   - Viewer is `user` (the requester) → user comments go
  ///     right, helpdesk/admin comments go left.
  bool get _isOutgoing =>
      currentRole != null && comment.role == currentRole;

  @override
  Widget build(BuildContext context) {
    // Avatar colour reflects the comment author's role:
    //   - `user` (requester) → purple
    //   - `helpdesk` / `admin` → blue
    final avatarColor = comment.role == UserRole.user
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF2563EB);
    final avatar = _Avatar(
      name: comment.author,
      color: avatarColor,
    );
    final bubble = _BubbleBody(comment: comment);

    if (_isOutgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: bubble),
          const SizedBox(width: 11.25),
          avatar,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 11.25),
        Flexible(child: bubble),
      ],
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final CommentEntity comment;
  const _BubbleBody({required this.comment});

  @override
  Widget build(BuildContext context) {
    // Responsive bubble — fills the available column width
    // (~350.5 on iPhone 12 Pro, ~730 on iPad) minus avatar
    // (32) + 11.25 gap. Height auto-sizes to content so longer
    // messages don't overflow on either resolution.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      padding: const EdgeInsets.all(12.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + date row — name on the left, date absolute-
          // positioned to the right edge of the bubble. The Stack
          // is forced to the full bubble width so `right: 0`
          // actually anchors to the right edge — without
          // `width: double.infinity` the Stack shrinks to the
          // name's intrinsic width, leaving a big gap between the
          // name text and the date.
          SizedBox(
            width: double.infinity,
            height: 19.5,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Text(
                    comment.author.isEmpty ? '—' : comment.author,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1115),
                      height: 19.5 / 13,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 2,
                  child: Text(
                    _dateLine(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 16.5 / 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3.75),
          // Role label
          Text(
            getRoleLabel(comment.role),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 16.5 / 11,
            ),
          ),
          const SizedBox(height: 6),
          // Message body — wraps naturally within the responsive
          // bubble (no maxLines / fixed height).
          Text(
            comment.message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F1115),
              height: 21 / 14,
            ),
          ),
        ],
      ),
    );
  }

  static String _dateLine(DateTime d) {
    final fmt = DateFormat('d MMM · HH:mm', 'id_ID');
    return fmt.format(d);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 12.16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 18.24 / 12.16,
        ),
      ),
    );
  }

  static String _initials(String s) {
    if (s.isEmpty) return '?';
    final parts = s.trim().split(RegExp(r'\s+|@'));
    if (parts.length >= 2) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    return s.substring(0, 1).toUpperCase();
  }
}

// ===========================================================================
// Reply bar (8071:707) — 37.5h input + send button
// ===========================================================================

class _ReplyBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_ReplyBar> createState() => _ReplyBarState();
}

class _ReplyBarState extends State<_ReplyBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final canSend =
        !widget.sending && widget.controller.text.trim().isNotEmpty;
    return Material(
      color: const Color(0xCCF5F7FA),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.authBorder, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18.75, 12.25, 18.75, 11.25),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 37.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.authBorder, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.25),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => canSend ? widget.onSend() : null,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0F1115),
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Write a reply…',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0x800F1115),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7.5),
              _SendButton(
                enabled: canSend,
                sending: widget.sending,
                onTap: widget.onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool sending;
  final VoidCallback onTap;
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? const Color(0xFF2563EB)
          : const Color(0xFF2563EB).withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 37.5,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sending)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.send_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 5.625),
              const Text(
                'Send',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 18.2 / 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Manage sheet (admin / helpdesk)
// ===========================================================================

class _ManageSheet extends StatelessWidget {
  final UserRole? role;
  final VoidCallback onStatus;
  final VoidCallback onAssign;
  final VoidCallback onDelete;
  const _ManageSheet({
    required this.role,
    required this.onStatus,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Admin sees all 3 actions; helpdesk only sees Update status.
    final isAdmin = role == UserRole.admin;
    final showAssign = isAdmin;
    final showDelete = isAdmin;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.authBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Manage ticket',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1115),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Update status'),
              subtitle: const Text(
                'Open, In Progress, Assigned, Closed',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              onTap: onStatus,
            ),
            if (showAssign)
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text('Assign to'),
                subtitle: const Text(
                  'Reassign to a helpdesk user',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                onTap: onAssign,
              ),
            if (showDelete)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.authError,
                ),
                title: const Text(
                  'Delete ticket',
                  style: TextStyle(color: AppColors.authError),
                ),
                subtitle: const Text(
                  'Permanently remove this ticket',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                onTap: onDelete,
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  final TicketStatus current;
  const _StatusSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final entries = <(TicketStatus, String, Color, Color)>[
      (TicketStatus.open, 'Open', AppColors.statusOpen, AppColors.statusOpenBg),
      (TicketStatus.assigned, 'Assigned', AppColors.statusAssigned, AppColors.statusAssignedBg),
      (TicketStatus.inProgress, 'In Progress', AppColors.statusInProgress, AppColors.statusInProgressBg),
      (TicketStatus.closed, 'Closed', AppColors.statusClosed, AppColors.statusClosedBg),
    ];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.authBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Update status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1115),
                  ),
                ),
              ),
            ),
            for (final e in entries)
              ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: e.$3,
                    borderRadius: BorderRadius.circular(33554400),
                  ),
                ),
                title: Text(
                  e.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        e.$1 == current ? FontWeight.w600 : FontWeight.w400,
                    color: e.$1 == current
                        ? e.$3
                        : const Color(0xFF0F1115),
                  ),
                ),
                trailing: e.$1 == current
                    ? Icon(Icons.check_rounded, color: e.$3, size: 18)
                    : null,
                onTap: () => Navigator.pop(context, e.$1),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _AssignSheet extends StatelessWidget {
  final List<HelpdeskUser> users;
  final String? currentName;
  const _AssignSheet({required this.users, required this.currentName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.authBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assign ticket',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1115),
                  ),
                ),
              ),
            ),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'No helpdesk users found.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              )
            else
              for (final u in users)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.authPrimary,
                    child: Text(
                      u.name.isNotEmpty
                          ? u.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(u.name),
                  subtitle: Text(u.department),
                  trailing: u.name == currentName
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.authPrimary, size: 18)
                      : null,
                  onTap: () => Navigator.pop(context, u),
                ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// History sheet (replacement for deleted TicketHistoryScreen)
// ===========================================================================
// Kept around as a fallback for callers that still want an inline
// modal timeline (the standard flow now navigates to TrackingScreen
// via `_TrackingLink.onTap`). Silenced from `unused_element` while
// the deprecation migration is still in flight.
// ignore: unused_element
class _HistorySheet extends StatelessWidget {
  final String ticketCode;
  final List<TicketHistoryEntity> events;
  const _HistorySheet({required this.ticketCode, required this.events});

  static const Map<String, IconData> _icons = {
    'created': Icons.fiber_new_rounded,
    'assigned': Icons.person_add_alt_1_rounded,
    'status_changed': Icons.swap_horiz_rounded,
    'closed': Icons.task_alt_rounded,
    'commented': Icons.chat_bubble_outline_rounded,
  };

  static const Map<String, Color> _colors = {
    'created': Color(0xFF2563EB),
    'assigned': Color(0xFF8B5CF6),
    'status_changed': Color(0xFFF59E0B),
    'closed': Color(0xFF43A047),
    'commented': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.authBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18.75, 12, 18.75, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F1115),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $ticketCode',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.authBorder),
                Expanded(
                  child: events.isEmpty
                      ? const Center(
                          child: Text(
                            'No events yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scroll,
                          padding:
                              const EdgeInsets.fromLTRB(18.75, 12, 18.75, 24),
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 11.25),
                          itemBuilder: (_, i) {
                            final e = events[events.length - 1 - i];
                            final color = _colors[e.action] ??
                                const Color(0xFF6B7280);
                            final icon = _icons[e.action] ??
                                Icons.history_rounded;
                            return _HistoryRow(
                              icon: icon,
                              color: color,
                              title: _titleFor(e),
                              subtitle: _subtitleFor(e),
                              at: e.createdAt,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _titleFor(TicketHistoryEntity e) {
    switch (e.action) {
      case 'created':
        return 'Ticket created';
      case 'assigned':
        return 'Assigned to ${e.toValue ?? '—'}';
      case 'status_changed':
        return 'Status ${e.fromValue ?? '?'} → ${e.toValue ?? '?'}';
      case 'closed':
        return 'Closed';
      case 'commented':
        return 'New comment';
      default:
        return e.action;
    }
  }

  String? _subtitleFor(TicketHistoryEntity e) {
    final actor = e.actorName;
    if (actor == null) return null;
    return 'by $actor';
  }
}

class _HistoryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final DateTime at;
  const _HistoryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y · HH:mm', 'id_ID');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 11.25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1115),
                  height: 19.5 / 14,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 16.5 / 12,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                fmt.format(at),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Loading + error states
// ===========================================================================

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.authBg,
        body: SafeArea(
          child: Stack(
            children: [
              const Center(child: CircularProgressIndicator()),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 81,
                  decoration: BoxDecoration(
                    color: const Color(0xCCF5F7FA),
                    border: Border(
                      bottom: BorderSide(
                          color: AppColors.authBorder, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorScaffold({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.authBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

// lib/presentation/screens/notification_screen.dart
//
// Phase B2 of the SRS v2.0.0 audit.
//
// Two surfaces:
//   * `NotificationPanel`  — bottom sheet from the bell icon
//   * `NotificationScreen` — full screen, accessed from the panel's
//                            "Lihat semua" link
//
// Both render the same list from `notificationsStreamProvider`.
// The bell calls `markAllAsRead` when the panel is opened so the
// badge clears.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification/mark_notification_read_usecase.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

/// Bottom sheet — opens from the bell icon. Mark-all-read happens
/// on first open.
class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    // Mark all read the first time the panel opens.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_marked) return;
      _marked = true;
      try {
        await ref.read(markAllNotificationsReadUseCaseProvider).call();
        ref.invalidate(unreadCountProvider);
      } catch (_) {
        // Non-fatal — the user can still see notifications.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notifications = notificationsAsync.valueOrNull ?? const [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen()),
                        );
                      },
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildList(context, notifications, scrollController,
                    compact: true),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full screen — accessed from "Lihat semua".
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notifications = notificationsAsync.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifications.any((n) => n.isUnread))
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(markAllNotificationsReadUseCaseProvider)
                      .call();
                  ref.invalidate(unreadCountProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.statusClosedBg,
                    ));
                  }
                }
              },
              child: const Text('Tandai dibaca'),
            ),
        ],
      ),
      body: _buildList(
        context,
        notifications,
        null,
        compact: false,
        isDark: isDark,
      ),
    );
  }
}

Widget _buildList(
  BuildContext context,
  List<NotificationEntity> notifications,
  ScrollController? scrollController, {
  required bool compact,
  bool isDark = false,
}) {
  if (notifications.isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: isDark ? AppColors.surfaceSubtleDark : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  final list = ListView.separated(
    controller: scrollController,
    padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
    itemCount: notifications.length,
    separatorBuilder: (_, __) => Divider(
      height: 1,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
    ),
    itemBuilder: (_, i) => _NotificationTile(
      notification: notifications[i],
      compact: compact,
      isDark: isDark,
    ),
  );
  return list;
}

class _NotificationTile extends ConsumerWidget {
  final NotificationEntity notification;
  final bool compact;
  final bool isDark;

  const _NotificationTile({
    required this.notification,
    required this.compact,
    required this.isDark,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'assigned':
        return Icons.person_add_alt_1_rounded;
      case 'status_changed':
        return Icons.sync_rounded;
      case 'commented':
        return Icons.chat_bubble_outline_rounded;
      case 'closed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _iconBg {
    switch (notification.type) {
      case 'assigned':
        return AppColors.statusAssignedBg;
      case 'status_changed':
        return AppColors.statusInProgressBg;
      case 'commented':
        return AppColors.statusOpenBg;
      case 'closed':
        return AppColors.statusClosedBg;
      default:
        return AppColors.statusAssignedBg;
    }
  }

  Color get _iconFg {
    switch (notification.type) {
      case 'assigned':
        return AppColors.statusAssigned;
      case 'status_changed':
        return AppColors.statusInProgress;
      case 'commented':
        return AppColors.statusOpen;
      case 'closed':
        return AppColors.statusClosed;
      default:
        return AppColors.statusAssigned;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notification.isUnread;
    return InkWell(
      onTap: () async {
        // Mark as read
        if (unread) {
          try {
            await ref
                .read(markNotificationReadUseCaseProvider)
                .call(MarkNotificationReadParams(notificationId: notification.id));
            ref.invalidate(unreadCountProvider);
          } catch (_) {}
        }
        // Close panel if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        // Navigate to ticket detail
        // Use the ticket_code (id) — the detail screen accepts both
        // uuid and code.
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TicketDetailScreen(ticketId: notification.ticketId),
            ),
          ).then((_) {
            // Refresh on return so the bell badge is up to date
            ref.invalidate(unreadCountProvider);
          });
        }
      },
      child: Container(
        color: unread
            ? (isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : const Color(0xFFEFF6FF))
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
            horizontal: 16, vertical: compact ? 10 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconFg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    return DateFormat('d MMM').format(when);
  }
}
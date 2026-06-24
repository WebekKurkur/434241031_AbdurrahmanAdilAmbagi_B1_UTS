// lib/presentation/screens/notification_screen.dart
//
// Redesign (2026-06-22) per Figma node 8071:111.
//
// 2026-06-24: Phase 7 of the theme refactor (ignore/todo-theme.md).
// Header, panel, grouped list, cards all read `context.semantic`
// so they flip with `Theme.of(context).brightness`. Brand colors
// stay fixed:
//   - blue #3B82F6 unread icon + dot
//   - blue #2563EB unread dot at right of card
//   - low-alpha brand tints for unread icon container

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification/mark_notification_read_usecase.dart';
import '../providers/notification_provider.dart';
import '../theme/app_semantic.dart';
import '../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────
// Public entry points
// ─────────────────────────────────────────────────────────────────

/// Bottom sheet — opens from the bell icon. Mark-all-read happens
/// on first open. (Unchanged from the previous version.)
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
    final c = context.semantic;
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
            color: c.surfaceCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border),
              Expanded(
                child: _buildPanelList(
                  context,
                  notifications,
                  scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildPanelList(
  BuildContext context,
  List<NotificationEntity> notifications,
  ScrollController scrollController,
) {
  final c = context.semantic;
  if (notifications.isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: c.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  return ListView.separated(
    controller: scrollController,
    padding: const EdgeInsets.symmetric(vertical: 4),
    itemCount: notifications.length,
    separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
    itemBuilder: (_, i) => _PanelTile(notification: notifications[i]),
  );
}

class _PanelTile extends ConsumerWidget {
  final NotificationEntity notification;
  const _PanelTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: Icon(
        _iconFor(notification.type),
        size: 18,
        color: _iconFgFor(notification.type),
      ),
      title: Text(
        notification.title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () async {
        if (notification.isUnread) {
          try {
            await ref
                .read(markNotificationReadUseCaseProvider)
                .call(MarkNotificationReadParams(
                    notificationId: notification.id));
            ref.invalidate(unreadCountProvider);
          } catch (_) {}
        }
        if (Navigator.canPop(context)) Navigator.pop(context);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TicketDetailScreen(ticketId: notification.ticketId),
            ),
          ).then((_) => ref.invalidate(unreadCountProvider));
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Full-screen NotificationScreen (Figma 8071:111 redesign)
// ─────────────────────────────────────────────────────────────────

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notifications = notificationsAsync.valueOrNull ?? const [];
    final unreadCount = notifications.where((n) => n.isUnread).length;

    return Scaffold(
      backgroundColor: context.semantic.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              unreadCount: unreadCount,
              loading: notificationsAsync.isLoading && notifications.isEmpty,
              onMarkAll: () async {
                try {
                  await ref
                      .read(markAllNotificationsReadUseCaseProvider)
                      .call();
                  ref.invalidate(unreadCountProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: AppColors.authError,
                      ),
                    );
                  }
                }
              },
            ),
            Expanded(
              child: notificationsAsync.isLoading && notifications.isEmpty
                  ? const _LoadingState()
                  : notifications.isEmpty
                      ? const _EmptyState()
                      : _GroupedList(notifications: notifications),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header (Figma 8071:1393-1407)
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int unreadCount;
  final bool loading;
  final VoidCallback onMarkAll;

  const _Header({
    required this.unreadCount,
    required this.loading,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 18.75, 18.75, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inbox',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.48,
                    height: 1.25,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    loading
                        ? 'Loading…'
                        : '$unreadCount unread',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillButton(
                icon: Icons.done_all_rounded,
                label: 'Mark all',
                onTap: unreadCount > 0 && !loading ? onMarkAll : null,
              ),
              const SizedBox(width: 7.5),
              const _IconPillButton(
                icon: Icons.tune_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 33.75,
          padding: const EdgeInsets.symmetric(horizontal: 12.25),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c.textSecondary),
              const SizedBox(width: 5.625),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  final IconData icon;
  const _IconPillButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return GestureDetector(
      onTap: () {
        // No-op for now — could open a filter sheet (e.g.
        // "Unread only") in a future pass.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filter not yet implemented'),
            duration: Duration(milliseconds: 800),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 33.75,
        height: 33.75,
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 16, color: c.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Grouped list
// ─────────────────────────────────────────────────────────────────

class _GroupedList extends ConsumerWidget {
  final List<NotificationEntity> notifications;
  const _GroupedList({required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _groupByDate(notifications);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Padding bottom clears the bottom nav pill (HomeScreen draws
      // its own bottom nav at the parent Scaffold level, so this
      // padding just keeps content from getting clipped).
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: g.label),
            Padding(
              padding: const EdgeInsets.fromLTRB(18.75, 7.5, 18.75, 0),
              child: Column(
                children: [
                  for (int j = 0; j < g.items.length; j++) ...[
                    if (j > 0) const SizedBox(height: 7.5),
                    _NotificationCard(
                      notification: g.items[j],
                      onTap: () =>
                          _onItemTap(context, ref, g.items[j]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onItemTap(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity n,
  ) async {
    if (n.isUnread) {
      try {
        await ref
            .read(markNotificationReadUseCaseProvider)
            .call(MarkNotificationReadParams(notificationId: n.id));
        ref.invalidate(unreadCountProvider);
      } catch (_) {}
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketId: n.ticketId),
        ),
      ).then((_) => ref.invalidate(unreadCountProvider));
    }
  }
}

class _NotificationGroup {
  final String label;
  final List<NotificationEntity> items;
  const _NotificationGroup({required this.label, required this.items});
}

/// Bucket notifications into "Today" + "Earlier". For now we
/// only have two buckets (matching the Figma spec). Future
/// enhancements: Yesterday / This week / Earlier this month.
List<_NotificationGroup> _groupByDate(List<NotificationEntity> all) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayItems = <NotificationEntity>[];
  final earlierItems = <NotificationEntity>[];
  for (final n in all) {
    final localCreated = n.createdAt.toLocal();
    final createdDay =
        DateTime(localCreated.year, localCreated.month, localCreated.day);
    if (!createdDay.isBefore(today)) {
      todayItems.add(n);
    } else {
      earlierItems.add(n);
    }
  }
  final groups = <_NotificationGroup>[];
  if (todayItems.isNotEmpty) {
    groups.add(
        _NotificationGroup(label: 'Today', items: todayItems));
  }
  if (earlierItems.isNotEmpty) {
    groups.add(
        _NotificationGroup(label: 'Earlier', items: earlierItems));
  }
  return groups;
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 0),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.semantic.textSecondary,
          letterSpacing: 0.66,
          height: 1.5,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final unread = notification.isUnread;
    // Unread icon container uses a low-alpha brand-blue overlay —
    // stays fixed across modes (reads OK on both surfaces).
    // Read icon container uses `tintNeutral` so it flips with
    // the theme.
    final iconBg = unread
        ? const Color(0x1F3B82F6) // rgba(59,130,246,0.12)
        : c.tintNeutral;
    final iconColor = unread
        ? const Color(0xFF3B82F6)
        : c.textSecondary;
    final iconData = _iconFor(notification.type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14.125),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container (33.75 × 33.75, radius 14)
            Container(
              width: 33.75,
              height: 33.75,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, size: 16, color: iconColor),
            ),
            const SizedBox(width: 11.25),
            // Title + body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.w600,
                            color: c.textPrimary,
                            height: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _formatRelative(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot — only for unread, aligned with title row.
            // Brand blue, fixed in both modes.
            if (unread) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 7.5),
                child: Container(
                  width: 7.5,
                  height: 7.5,
                  decoration: const BoxDecoration(
                    color: AppColors.authPrimary,
                    shape: BoxShape.circle,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: c.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "We'll let you know when something happens",
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared icon / colour helpers
// ─────────────────────────────────────────────────────────────────

IconData _iconFor(String type) {
  switch (type) {
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

Color _iconFgFor(String type) {
  // These map to status colors (open / assigned / in-progress /
  // closed) and stay fixed across modes.
  switch (type) {
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

String _formatRelative(DateTime when) {
  final now = DateTime.now();
  final local = when.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  // > 7d: show date. The Figma spec shows "2d" / "5d" up to a
  // week and falls back to a date label after that.
  return '${diff.inDays}d';
}

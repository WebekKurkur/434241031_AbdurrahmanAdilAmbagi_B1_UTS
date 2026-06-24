// lib/presentation/widgets/notification_bell.dart
//
// Phase B2: bell icon + unread badge.
//
// Drop into any AppBar.actions list (or a Row inside a custom
// header). The bell subscribes to `unreadCountProvider` and shows
// a red dot with the count. Tapping opens the notification panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../screens/notification_screen.dart';

class NotificationBell extends ConsumerWidget {
  /// Color of the bell icon itself. Use white when on a
  /// gradient/colored header, the AppBar's `foregroundColor`
  /// otherwise.
  final Color iconColor;

  /// When `true`, shows only a small red dot in the top-right
  /// corner instead of the numeric pill badge. Useful in custom
  /// headers where the screen real-estate is tight and a count
  /// would clash with the surrounding design (e.g. the slim
  /// tracking-screen / ticket-detail / user-management
  /// AppHeaders, where the existing 33.75px theme-toggle button
  /// is the visual anchor on the right edge).
  final bool dotOnly;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.dotOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;
    final showBadge = unread > 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          icon: Icon(Icons.notifications_none_rounded, color: iconColor),
          onPressed: () => _openPanel(context),
        ),
        // Badge — only shown when unread > 0
        if (showBadge)
          Positioned(
            top: dotOnly ? 8 : 6,
            right: dotOnly ? 8 : 6,
            child: dotOnly
                // Small red dot — matches the user's "red dot on
                // the up-right side of the icon" requirement.
                // 8×8 px, no number, with a thin white ring so it
                // pops on coloured backgrounds.
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  )
                // Numeric pill — preserved from Phase B2 for
                // any caller that wants the unread count.
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
      ],
    );
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationPanel(),
    );
  }
}
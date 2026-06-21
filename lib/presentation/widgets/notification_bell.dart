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

  const NotificationBell({super.key, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          icon: Icon(Icons.notifications_none_rounded, color: iconColor),
          onPressed: () => _openPanel(context),
        ),
        // Badge — only shown when unread > 0
        if (unreadAsync.valueOrNull != null && unreadAsync.value! > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unreadAsync.value! > 9 ? '9+' : '${unreadAsync.value}',
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
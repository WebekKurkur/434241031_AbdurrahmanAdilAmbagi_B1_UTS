// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'ticket_list_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: _buildScreen(_currentIndex),
      // FAB is owned by DashboardScreen per Figma node 8071:3.
      // Bottom-nav pill matches Figma node 8077:2878:
      //   - 50.5 px tall white pill, 15 px radius
      //   - 1 px #e5e7eb border
      //   - 6 px blur shadow at 8 % opacity (offset 0,4)
      //   - 4 equal-width tabs, 20 px icon, 10 px label
      //   - active tab: #2563eb icon + label (w600), 30×3.75
      //     blue pill above the icon
      bottomNavigationBar: Material(
        color: AppColors.authBg,
        elevation: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 7.5, 15, 15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double tabCount = 4;
                const double barWidth = 30;
                const double barHeight = 3.75;
                final double tabW = constraints.maxWidth / tabCount;
                final double barLeft =
                    tabW * _currentIndex + (tabW - barWidth) / 2;
                return Container(
                  height: 50.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.authBorder),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F1115),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildNavItem(
                                  0,
                                  Icons.dashboard_outlined,
                                  Icons.dashboard_rounded,
                                  'Home',
                                  isDark)),
                          Expanded(
                              child: _buildNavItem(
                                  1,
                                  Icons.confirmation_number_outlined,
                                  Icons.confirmation_number_rounded,
                                  'Tickets',
                                  isDark)),
                          Expanded(
                              child: _buildNavItem(
                                  2,
                                  Icons.notifications_outlined,
                                  Icons.notifications_rounded,
                                  'Inbox',
                                  isDark)),
                          Expanded(
                              child: _buildNavItem(
                                  3,
                                  Icons.person_outline_rounded,
                                  Icons.person_rounded,
                                  'Profile',
                                  isDark)),
                        ],
                      ),
                      // Active-tab indicator: 30 × 3.75 px blue pill
                      // that sits ON TOP of the container edge
                      // (top: -3.75) and is centered horizontally
                      // over the active tab. Figma node 8077:2886.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        top: -barHeight,
                        left: barLeft,
                        child: Container(
                          width: barWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.authPrimary,
                            borderRadius:
                                BorderRadius.circular(33554400),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          onSwitchToTab: (i) => setState(() => _currentIndex = i),
        );
      case 1:
        return const TicketListScreen();
      case 2:
        return const NotificationScreen();
      case 3:
        return const ProfileScreen();
      default:
        return DashboardScreen(
          onSwitchToTab: (i) => setState(() => _currentIndex = i),
        );
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    // The Inbox tab (index 2) shows a small red dot in the
    // top-right of the bell icon when there are unread
    // notifications — matches the bell-with-dot pattern from
    // the user's spec.
    final unreadAsync =
        index == 2 ? ref.watch(unreadCountProvider) : null;
    final unread = unreadAsync?.valueOrNull ?? 0;
    final showDot = index == 2 && unread > 0;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected
                    ? AppColors.authPrimary
                    : AppColors.authHint,
              ),
              if (showDot)
                Positioned(
                  // 7×7 red dot, sitting on the top-right corner
                  // of the 20×20 icon. The `right: -2 / top: -2`
                  // nudges it just outside the icon bounds so it
                  // doesn't clip behind the icon stroke.
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 1.875),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.authPrimary
                  : AppColors.authHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

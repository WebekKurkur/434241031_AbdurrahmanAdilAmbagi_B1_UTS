// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'ticket_list_screen.dart';
import 'profile_screen.dart';
import 'create_ticket_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _buildScreen(_currentIndex),
      floatingActionButton: currentUser?.role == UserRole.user
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateTicketScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Material(
        color: isDark ? AppColors.cardDark : Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined,
                    Icons.dashboard_rounded, 'Dashboard', isDark),
                _buildNavItem(
                    1,
                    Icons.confirmation_number_outlined,
                    Icons.confirmation_number_rounded,
                    'Tiket',
                    isDark),
                _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded,
                    'Profil', isDark),
              ],
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
        return const ProfileScreen();
      default:
        return DashboardScreen(
          onSwitchToTab: (i) => setState(() => _currentIndex = i),
        );
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

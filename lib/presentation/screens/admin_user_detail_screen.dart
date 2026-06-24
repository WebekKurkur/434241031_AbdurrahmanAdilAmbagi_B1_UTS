// lib/presentation/screens/admin_user_detail_screen.dart
//
// Redesign (Figma 8100:1483) — "User Detail" screen for admins.
//
// Layout (top → bottom):
//   - 52.5h frosted AppHeader with back + "User Detail" + username
//     subtitle + theme toggle
//   - Hero card: 56px purple avatar + name (17px Bold) + email +
//     (role pill + dot + active label)
//   - "ACCOUNT INFO" section + 1 row: department icon + label +
//     value
//   - "ACTIONS" section + 1 row: green icon + "active account" +
//     iOS-style blue toggle (#2563eb, white knob)
//   - Full-width blue 42h "simpan perubahan" button — only enabled
//     when the active state has been changed
//
// Tapping save calls `currentUserProvider.notifier.updateUser` with
// the toggled `isActive` and pops back to the list, which is
// auto-refreshed by invalidating `adminUsersProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/update_user_usecase.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.user.isActive;
  }

  bool get _hasChanges => _isActive != widget.user.isActive;

  Future<void> _save() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(currentUserProvider.notifier).updateUser(
            UpdateUserParams(
              targetUserId: widget.user.id,
              isActive: _isActive,
            ),
          );
      if (!mounted) return;
      ref.invalidate(adminUsersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengguna ${updated.name} berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.statusOpen,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppHeader(username: widget.user.username),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 37.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(user: widget.user),
                    const SizedBox(height: 15),
                    const _SectionLabel(text: 'Account info'),
                    const SizedBox(height: 7.5),
                    _AccountInfoCard(department: widget.user.department),
                    const SizedBox(height: 15),
                    const _SectionLabel(text: 'Actions'),
                    const SizedBox(height: 7.5),
                    _ActionsCard(
                      isActive: _isActive,
                      disabled: widget.user.id ==
                          ref.read(currentUserProvider)?.id,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const SizedBox(height: 15),
                    _SaveButton(
                      enabled: _hasChanges && !_isSaving,
                      loading: _isSaving,
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// AppHeader (8100:1761) — 52.5h frosted, back + title + username + toggle
// ===========================================================================

class _AppHeader extends ConsumerWidget {
  final String username;
  const _AppHeader({required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Container(
      height: 52.5,
      decoration: const BoxDecoration(
        color: Color(0xCCF5F7FA), // 80% #f5f7fa
        border: Border(
          bottom: BorderSide(color: AppColors.authBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.75),
        child: Row(
          children: [
            // Back button — 20px icon, -7.5px negative margin
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
                      child: const SizedBox(
                        width: 33.75,
                        height: 33.75,
                        child: Icon(
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
            // "User Detail" title + username subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Detail',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1115),
                      letterSpacing: -0.17,
                      height: 22.1 / 17,
                    ),
                  ),
                  Text(
                    username.isEmpty ? '—' : username,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 15.6 / 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Theme toggle (8100:1771) — 33.75×33.75 bordered
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
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// HeroCard (8100:1775) — 56px purple avatar + name + email + role pill +
// dot + active label
// ===========================================================================

class _HeroCard extends StatelessWidget {
  final UserEntity user;
  const _HeroCard({required this.user});

  static const Map<UserRole, IconData> _roleIcons = {
    UserRole.user: Icons.person_rounded,
    UserRole.helpdesk: Icons.headset_mic_rounded,
    UserRole.admin: Icons.admin_panel_settings_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final roleLabel = _labelFor(user.role);
    final roleIcon = _roleIcons[user.role] ?? Icons.person_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.authBorder, width: 1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F1115), // ≈ rgba(15,17,21,0.06)
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — 56px purple
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user.name),
              style: const TextStyle(
                fontSize: 21.28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 31.92 / 21.28,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Name + email + (role pill + dot + active)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1115),
                    height: 25.5 / 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 18 / 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7.5),
                Row(
                  children: [
                    // Role pill (8100:1785) — #f1f4f8 bg, 11px icon +
                    // 11px Semi Bold label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9.375,
                        vertical: 1.875,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.circular(33554400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            roleIcon,
                            size: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 5.625),
                          Text(
                            ' $roleLabel',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              height: 16.5 / 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5.625),
                    // Green dot + Active label
                    Container(
                      width: 5.625,
                      height: 5.625,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5.625),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: user.isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                        height: 16.5 / 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.helpdesk:
        return 'Helpdesk';
      case UserRole.user:
        return 'User';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ===========================================================================
// SectionLabel — uppercase 11px Semi Bold 0.66 tracking
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
// AccountInfoCard (8100:1797) — 55h white 15px-radius card with 1 row
// (department)
// ===========================================================================

class _AccountInfoCard extends StatelessWidget {
  final String department;
  const _AccountInfoCard({required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.authBorder, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: _InfoRow(
        iconData: Icons.business_rounded,
        label: 'Department',
        value: department.isEmpty ? '—' : department,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String value;
  const _InfoRow({
    required this.iconData,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11.25),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 15, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 11.25),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
                height: 19.5 / 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F1115),
              height: 19.5 / 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ActionsCard (8100:1928) — 56h white 15px-radius card with 1 row
// (active account toggle)
// ===========================================================================

class _ActionsCard extends StatelessWidget {
  final bool isActive;
  final bool disabled;
  final ValueChanged<bool> onChanged;
  const _ActionsCard({
    required this.isActive,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.authBorder, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11.25),
        child: Row(
          children: [
            // Green icon container (8100:1930) — 30px, rgba(16,185,129,0.14)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0x1410B981),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 11.25),
            const Expanded(
              child: Text(
                'active account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F1115),
                  height: 19.6 / 14,
                ),
              ),
            ),
            // iOS-style blue toggle (8100:2000) — 37.5×22.5, white knob
            // (knob position: left=1.75 / right=36.63 → 19px wide)
            GestureDetector(
              onTap: disabled ? null : () => onChanged(!isActive),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 37.5,
                height: 22.5,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(33554400),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(1.75),
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F0F1115), // 0,1,2 rgba(15,17,21,0.06)
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SaveButton (8100:1997) — 42h full-width blue 18px-radius
// ===========================================================================

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  const _SaveButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 42,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'simpan perubahan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 21 / 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

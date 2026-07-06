// lib/presentation/screens/admin_user_list_screen.dart
//
// "User Management" screen.
//
// Layout (top → bottom):
//   - 52.5h frosted AppHeader with back + "User Management"
//   - 3 summary chips (Total / Active / Helpdesk), flex-1 each
//   - Search bar + blue 37.5px "+" add-user button
//   - 4 filter pills (All / Admin / Helpdesk / User) — selected
//     pill inverts via `c.textPrimary` bg (auto-flips black-on-
//     light → near-white-on-dark) and `c.surface` text
//   - Vertical list of user cards: 40px purple avatar + name +
//     email + role pill (with icon) + dot + department + 30px
//     chevron button. Tapping the card or the chevron opens the
//     admin user-detail screen for that user.
//
// Data: `adminUsersProvider` (FutureProvider.autoDispose) from
// `presentation/providers/auth_provider.dart`.
//
// AppHeader, summary chips, search field, filter pills, user
// card, role pill, loading + error + empty states all read
// `context.semantic` so they flip with `Theme.of(context).brightness`.
// Brand colors stay fixed:
//   - blue #2563EB (add-user button, "Helpdesk" summary text)
//   - green #10B981 ("Active" summary text + tinted bg)
//   - blue #3B82F6 (role pill text + icon, helpdesk + user roles)
//   - purple #8B5CF6 (user avatar, admin role color)
//   - low-alpha brand tints for summary/role-pill bgs
//   - white on avatar text + "+" icon (sits on colored bg)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../theme/app_semantic.dart';
import 'admin_user_detail_screen.dart';

class AdminUserListScreen extends ConsumerWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: context.semantic.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _AppHeader(),
            Expanded(
              child: usersAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(adminUsersProvider),
                ),
                data: (users) => _UserListBody(users: users),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// AppHeader (8098:1184) — 52.5h frosted, back + title + theme toggle
// ===========================================================================

class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.semantic;
    return Container(
      height: 52.5,
      decoration: BoxDecoration(
        color: c.surfaceFrosted, // 80% surface alpha
        border: Border(
          bottom: BorderSide(color: c.border, width: 1),
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
                      child: SizedBox(
                        width: 33.75,
                        height: 33.75,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11.25),
            Expanded(
              child: Text(
                'User Management',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  letterSpacing: -0.17,
                  height: 22.1 / 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // (Theme toggle removed — lives on profile + settings
            // per the latest IA)
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Body — stack of [summary chips, search+add, filter pills, user list]
// ===========================================================================

class _UserListBody extends StatefulWidget {
  final List<UserEntity> users;
  const _UserListBody({required this.users});

  @override
  State<_UserListBody> createState() => _UserListBodyState();
}

class _UserListBodyState extends State<_UserListBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _RoleFilter _filter = _RoleFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserEntity> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.users.where((u) {
      if (_filter != _RoleFilter.all && u.role != _filter.role) {
        return false;
      }
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.department.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.users.length;
    final active = widget.users.where((u) => u.isActive).length;
    final helpdesk =
        widget.users.where((u) => u.role == UserRole.helpdesk).length;

    return Column(
      children: [
        // Summary chips (8098:1195-1204)
        Padding(
          padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 11.25),
          child: Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  value: total,
                  label: 'Total',
                  // "Total" chip — neutral surface in both modes.
                  background: context.semantic.surfaceCard,
                  border: context.semantic.border,
                  textColor: context.semantic.textPrimary,
                ),
              ),
              const SizedBox(width: 11.25),
              Expanded(
                child: _SummaryChip(
                  value: active,
                  label: 'Active',
                  // Brand green low-alpha tint (reads OK on both
                  // card surfaces).
                  background: const Color(0x1410B981),
                  border: context.semantic.border,
                  textColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 11.25),
              Expanded(
                child: _SummaryChip(
                  value: helpdesk,
                  label: 'Helpdesk',
                  // Brand blue low-alpha tint (reads OK on both
                  // card surfaces).
                  background: const Color(0x143B82F6),
                  border: context.semantic.border,
                  textColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
        // Search + add (8098:1205-1216)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.75),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 7.5),
              _AddUserButton(
                onTap: () => Navigator.pushNamed(context, '/register'),
              ),
            ],
          ),
        ),
        // Filter pills (8098:1218-1226)
        SizedBox(
          height: 37.5,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18.75, 11.25, 18.75, 0),
            child: Row(
              children: [
                for (final f in _RoleFilter.values) ...[
                  _FilterPill(
                    label: f.label,
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  if (f != _RoleFilter.values.last) const SizedBox(width: 5.625),
                ],
              ],
            ),
          ),
        ),
        // User list
        Expanded(
          child: _visible.isEmpty
              ? _EmptyState(filter: _filter, query: _query)
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18.75, 15, 18.75, 30),
                  itemCount: _visible.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 11.25),
                    child: _UserCard(
                      user: _visible[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserDetailScreen(
                            user: _visible[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

enum _RoleFilter {
  all,
  admin,
  helpdesk,
  user;

  String get label {
    switch (this) {
      case _RoleFilter.all:
        return 'All';
      case _RoleFilter.admin:
        return 'Admin';
      case _RoleFilter.helpdesk:
        return 'Helpdesk';
      case _RoleFilter.user:
        return 'User';
    }
  }

  UserRole? get role {
    switch (this) {
      case _RoleFilter.all:
        return null;
      case _RoleFilter.admin:
        return UserRole.admin;
      case _RoleFilter.helpdesk:
        return UserRole.helpdesk;
      case _RoleFilter.user:
        return UserRole.user;
    }
  }
}

// ===========================================================================
// SummaryChip (8098:1196) — flex-1, 18px radius, value + label stacked
// ===========================================================================

class _SummaryChip extends StatelessWidget {
  final int value;
  final String label;
  final Color background;
  final Color border;
  final Color textColor;
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.375, horizontal: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 27 / 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textColor.withValues(alpha: 0.85),
              height: 16.5 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SearchField (8098:1206) — surfaceCard, 18px radius, search icon + text
// ===========================================================================

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Container(
      height: 37.5,
      decoration: BoxDecoration(
        // Subtle inset: tintNeutral sits 1-2% lighter than the
        // page surface (light) / 6% lighter (dark), so the
        // search field reads as a field without the high-
        // contrast white-on-lightgrey look.
        color: c.tintNeutral,
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.25),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 15,
            color: c.textSecondary,
          ),
          const SizedBox(width: 7.5),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                color: c.textPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'Search users…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  // 50% alpha of the primary text — the hint
                  // dims correctly in both modes.
                  color: c.textPrimary.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// AddUserButton (8098:1212) — 37.5px brand-blue circle with "+" icon
// ===========================================================================

class _AddUserButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddUserButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      // Brand blue — stays #2563EB in both modes.
      color: const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(
          width: 37.5,
          height: 37.5,
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: 16,
            // White on blue — stays white in both modes.
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// FilterPill (8098:1219-1226) — 26.25h, pill-shaped
//   selected: inverts via c.textPrimary bg + c.surface fg
//             (auto-flips black-on-light → near-white-on-dark)
//   unselected: transparent bg + c.textSecondary fg + c.border
// ===========================================================================

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    // Inversion trick: when selected, use textPrimary as bg
    // (dark in light mode, near-white in dark mode) and surface
    // as fg (light in light mode, dark in dark mode). This
    // mirrors the active filter chip in ticket_list_screen.
    final bg = selected ? c.textPrimary : Colors.transparent;
    final fg = selected ? c.surface : c.textSecondary;
    final border = selected ? c.textPrimary : c.border;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(33554400),
      child: InkWell(
        borderRadius: BorderRadius.circular(33554400),
        onTap: onTap,
        child: Container(
          height: 26.25,
          padding: const EdgeInsets.symmetric(horizontal: 12.25),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(33554400),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 16.8 / 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// UserCard (8098:1382) — 40px purple avatar + name + email +
// role pill + dot + department + 30px chevron button
// ===========================================================================

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;
  const _UserCard({required this.user, required this.onTap});

  // Role-specific brand colors — kept fixed across light/dark.
  static const Map<UserRole, Color> _roleColors = {
    UserRole.user: Color(0xFF3B82F6),
    UserRole.helpdesk: Color(0xFF3B82F6),
    UserRole.admin: Color(0xFF8B5CF6),
  };

  static const Map<UserRole, IconData> _roleIcons = {
    UserRole.user: Icons.person_rounded,
    UserRole.helpdesk: Icons.headset_mic_rounded,
    UserRole.admin: Icons.admin_panel_settings_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final color = _roleColors[user.role] ?? const Color(0xFF8B5CF6);
    final roleIcon = _roleIcons[user.role] ?? Icons.person_rounded;
    final roleLabel = _labelFor(user.role);

    return Material(
      color: c.surfaceCard,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.border, width: 1),
            boxShadow: [
              BoxShadow(
                // 6% black in light mode, 10% white in dark mode
                // (avoids the "invisible shadow on dark bg" trap
                // — the old literal #0F0F1115 would not show on
                // a #0F0F1115 dark page).
                color: c.shadow,
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar — 40px brand purple, white initials
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(user.name),
                  style: const TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 22.8 / 15.2,
                  ),
                ),
              ),
              const SizedBox(width: 11.25),
              // Name + email + (role pill · department)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 21,
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          height: 21 / 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1.875),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        height: 18 / 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7.5),
                    Row(
                      children: [
                        _RolePill(
                          label: roleLabel,
                          icon: roleIcon,
                          color: color,
                        ),
                        const SizedBox(width: 11.25),
                        Container(
                          width: 3.75,
                          height: 3.75,
                          decoration: BoxDecoration(
                            color: c.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 11.25),
                        Flexible(
                          child: Text(
                            user.department.isEmpty
                                ? '—'
                                : user.department,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                              height: 16.5 / 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron button (8098:1404) — 30px rounded, no bg
              const SizedBox(width: 7.5),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
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
// RolePill — small rounded pill with icon + label, used inside the
// user card.
// ===========================================================================

class _RolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _RolePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 1.875),
      decoration: BoxDecoration(
        // Brand blue low-alpha tint (reads OK on both card
        // surfaces).
        color: const Color(0x143B82F6),
        borderRadius: BorderRadius.circular(33554400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3.75),
          Text(
            ' $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              height: 16.5 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Loading + Error + Empty states
// ===========================================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: c.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat daftar pengguna',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _RoleFilter filter;
  final String query;
  const _EmptyState({required this.filter, required this.query});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 56,
              color: c.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'No users match "$query"'
                  : 'No ${filter.label.toLowerCase()} users',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

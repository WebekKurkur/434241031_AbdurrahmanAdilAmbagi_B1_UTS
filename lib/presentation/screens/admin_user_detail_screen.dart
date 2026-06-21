// lib/presentation/screens/admin_user_detail_screen.dart
//
// Phase E of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-007: Admin edits another user's role / active state /
// department. Receives a `UserEntity` as a route argument, lets
// the admin mutate it via the `admin_update_user` RPC, then
// pops back with the updated entity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/update_user_usecase.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  late UserRole _selectedRole;
  late bool _isActive;
  late TextEditingController _departmentController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _departmentController =
        TextEditingController(text: widget.user.department);
  }

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }

  bool _detectChanges() {
    return _selectedRole != widget.user.role ||
        _isActive != widget.user.isActive ||
        _departmentController.text.trim() != widget.user.department;
  }

  Future<void> _save() async {
    if (!_detectChanges()) {
      setState(() => _hasChanges = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(currentUserProvider.notifier).updateUser(
            UpdateUserParams(
              targetUserId: widget.user.id,
              role: _selectedRole != widget.user.role ? _selectedRole : null,
              isActive: _isActive != widget.user.isActive ? _isActive : null,
              department: _departmentController.text.trim() !=
                      widget.user.department
                  ? _departmentController.text.trim()
                  : null,
            ),
          );
      if (!mounted) return;

      // Refresh the list provider so the next open shows fresh data
      ref.invalidate(adminUsersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengguna ${updated.name} berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.statusClosed,
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

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buang Perubahan?'),
        content: const Text(
            'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOpen),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(_selectedRole);
    final roleIcon = _getRoleIcon(_selectedRole);
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.id == widget.user.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardChanges()) {
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pengguna'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withValues(alpha: 0.7),
                        roleColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(roleIcon, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  widget.user.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (isSelf) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ini adalah akun Anda',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Username (read-only)
              _SectionLabel(label: 'Username', isDark: isDark),
              const SizedBox(height: 6),
              _ReadOnlyField(value: widget.user.username, isDark: isDark),
              const SizedBox(height: 16),

              // Role selector
              _SectionLabel(label: 'Role', isDark: isDark),
              const SizedBox(height: 6),
              _RoleSelector(
                selectedRole: _selectedRole,
                onChanged: (role) {
                  setState(() {
                    _selectedRole = role;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Department
              _SectionLabel(label: 'Departemen', isDark: isDark),
              const SizedBox(height: 6),
              TextField(
                controller: _departmentController,
                onChanged: (_) {
                  setState(() => _hasChanges = _detectChanges());
                },
                decoration: const InputDecoration(
                  labelText: 'Departemen',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Active toggle
              _SectionLabel(label: 'Status Akun', isDark: isDark),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2D3F55)
                        : const Color(0xFFE8EDF5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? const Color(0xFFE6F4EA)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isActive
                            ? Icons.check_circle_outline_rounded
                            : Icons.block_rounded,
                        size: 18,
                        color: _isActive
                            ? const Color(0xFF43A047)
                            : const Color(0xFFEF5350),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isActive ? 'Akun Aktif' : 'Akun Nonaktif',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _isActive
                                ? 'Pengguna dapat login'
                                : 'Pengguna tidak dapat login',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isActive,
                      activeThumbColor: AppColors.statusClosed,
                      onChanged: isSelf
                          ? null
                          : (val) {
                              setState(() {
                                _isActive = val;
                                _hasChanges = true;
                              });
                            },
                    ),
                  ],
                ),
              ),
              if (isSelf) ...[
                const SizedBox(height: 8),
                Text(
                  'Anda tidak dapat menonaktifkan akun sendiri',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _hasChanges && !_isSaving ? _save : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Menyimpan…' : 'Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.helpdesk:
        return Icons.headset_mic_rounded;
      case UserRole.user:
        return Icons.person_rounded;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final bool isDark;
  const _ReadOnlyField({required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3F55) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = selectedRole == role;
        Color color;
        IconData icon;
        String label;
        switch (role) {
          case UserRole.user:
            color = const Color(0xFF00838F);
            icon = Icons.person_rounded;
            label = 'User';
            break;
          case UserRole.helpdesk:
            color = AppColors.primary;
            icon = Icons.headset_mic_rounded;
            label = 'Helpdesk';
            break;
          case UserRole.admin:
            color = const Color(0xFF7B1FA2);
            icon = Icons.admin_panel_settings_rounded;
            label = 'Admin';
            break;
        }
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 22, color: isSelected ? color : Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
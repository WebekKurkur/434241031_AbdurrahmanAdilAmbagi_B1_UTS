// lib/presentation/screens/register_screen.dart
//
// Phase C1 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-003 Register: username + name + email + password + confirm
// password + role + department. Routes to /home on success.
//
// Note: this is self-service registration. In a real prod
// environment you'd typically disable public sign-up and have an
// admin invite users. For SRS compliance the Supabase project has
// `auto_confirm: true` so the new account is immediately usable.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _departmentController = TextEditingController();
  UserRole _role = UserRole.user;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  String? _required(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field harus diisi';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email harus diisi';
    final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username harus diisi';
    final trimmed = v.trim();
    if (trimmed.length < 3) return 'Username minimal 3 karakter';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Username hanya boleh huruf, angka, dan underscore';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password harus diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordController.text) return 'Password tidak cocok';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final user = await ref.read(currentUserProvider.notifier).register(
            RegisterParams(
              username: _usernameController.text.trim(),
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              role: _role,
              department: _departmentController.text.trim(),
            ),
          );

      if (!mounted) return;

      if (user != null) {
        // Success → route to home.
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage =
            'Pendaftaran gagal. Silakan coba lagi dengan data lain.');
      }
    } catch (e) {
      if (!mounted) return;
      // Strip the noisy "AuthRetryableFetchException: " prefix.
      final msg = e.toString().replaceFirst('AuthRetryableFetchException: ', '');
      setState(() => _errorMessage = 'Pendaftaran gagal: $msg');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                  // Header
                  Text(
                    'Daftar Akun',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buat akun baru untuk mulai menggunakan HelpDesk',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role selector
                          Text(
                            'Daftar sebagai',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: UserRole.values.map((role) {
                              final isSelected = _role == role;
                              final config = _roleConfig(role);
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _role = role),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.1)
                                          : isDark
                                              ? const Color(0xFF1E293B)
                                              : AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          config.icon,
                                          size: 20,
                                          color: isSelected
                                              ? AppColors.primary
                                              : isDark
                                                  ? AppColors.textMuted
                                                  : AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          config.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.primary
                                                : isDark
                                                    ? AppColors.textMuted
                                                    : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          _Field(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person_outline_rounded,
                            validator: _validateUsername,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _nameController,
                            label: 'Nama Lengkap',
                            icon: Icons.badge_outlined,
                            validator: (v) => _required(v, 'Nama lengkap'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _departmentController,
                            label: 'Departemen',
                            icon: Icons.business_outlined,
                            validator: (v) => _required(v, 'Departemen'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            isDark: isDark,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            onChanged: (_) =>
                                _formKey.currentState?.validate(),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _confirmController,
                            label: 'Konfirmasi Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirm,
                            validator: _validateConfirm,
                            isDark: isDark,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFEF5350), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFEF5350),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : const Text('Daftar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                  'Sudah punya akun? Masuk di sini'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool isDark;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}

class _RoleConfig {
  final IconData icon;
  final String label;
  const _RoleConfig(this.icon, this.label);
}

_RoleConfig _roleConfig(UserRole role) {
  switch (role) {
    case UserRole.user:
      return const _RoleConfig(Icons.person_outline_rounded, 'User');
    case UserRole.helpdesk:
      return const _RoleConfig(Icons.headset_mic_outlined, 'Helpdesk');
    case UserRole.admin:
      return const _RoleConfig(
          Icons.admin_panel_settings_outlined, 'Admin');
  }
}
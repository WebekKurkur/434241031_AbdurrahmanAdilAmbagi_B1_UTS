// lib/presentation/screens/forgot_password_screen.dart
//
// Reset-password screen.
//
// 2026-06-25 update: instead of sending a reset email, the user
// enters their email + current password + new password right
// here. One-screen flow, no email round-trip, no token, no
// expiry.
//
// Two states:
//   1. Form: back-link + heading + email field + old-password
//      field + new-password field + confirm-new-password field +
//      "Change password" button.
//   2. Success: green checkmark + confirmation + "Back to login".

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/auth/change_password_usecase.dart';
import '../providers/auth_provider.dart';
import '../theme/app_semantic.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email harus diisi';
    // Accept either a plain username (no `@`) or a full email.
    // The repository resolves usernames via the `profiles`
    // table so the user can keep typing `user` / `helpdesk` /
    // `admin` from the login screen convention.
    final trimmed = v.trim();
    if (!trimmed.contains('@')) {
      if (trimmed.length < 3) return 'Email / username minimal 3 karakter';
      return null;
    }
    final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(trimmed)) return 'Format email tidak valid';
    return null;
  }

  String? _validateOldPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password lama harus diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password baru harus diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    if (v == _oldPasswordController.text) {
      return 'Password baru tidak boleh sama dengan yang lama';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Konfirmasi password harus diisi';
    if (v != _newPasswordController.text) {
      return 'Konfirmasi tidak cocok dengan password baru';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final oldPwd = _oldPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    final emailErr = _validateEmail(email);
    final oldErr = _validateOldPassword(oldPwd);
    final newErr = _validateNewPassword(newPwd);
    final confirmErr = _validateConfirmPassword(confirmPwd);
    final firstErr = emailErr ?? oldErr ?? newErr ?? confirmErr;
    if (firstErr != null) {
      setState(() => _errorMessage = firstErr);
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .changePassword(ChangePasswordParams(
            email: email,
            oldPassword: oldPwd,
            newPassword: newPwd,
          ));
      if (!mounted) return;
      setState(() {
        _sent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Supabase errors arrive wrapped in AuthRetryableFetch /
        // AuthException. Strip known prefixes so the UI shows a
        // clean Indonesian message.
        final raw = e.toString();
        final stripped = raw
            .replaceFirst('AuthRetryableFetchException: ', '')
            .replaceFirst('AuthException: ', '')
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Exception: ', '');
        _errorMessage = 'Gagal ubah password: $stripped';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackLink(),
          const SizedBox(height: 22.5),
          _buildHeading(),
          const SizedBox(height: 22.5),
          _sent ? _buildSuccessView() : _buildFormView(),
        ],
      ),
    );
  }

  Widget _buildBackLink() {
    final c = context.semantic;
    return GestureDetector(
      onTap: _isLoading ? null : () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            size: 14,
            color: c.textSecondary,
          ),
          const SizedBox(width: 5.625),
          Text(
            'Back to sign in',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeading() {
    final c = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset your password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.48,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3.75),
        Text(
          'Masukkan email, password lama, dan password baru untuk '
          'mengubah password akun Anda.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 80.ms, duration: 300.ms);
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          icon: Icons.alternate_email_rounded,
          hint: 'you@company.id atau username',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.lock_outline_rounded,
          hint: 'Password lama',
          controller: _oldPasswordController,
          obscureText: _obscureOld,
          textInputAction: TextInputAction.next,
          validator: _validateOldPassword,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          suffixIcon: _obscureSuffix(_obscureOld, () {
            setState(() => _obscureOld = !_obscureOld);
          }),
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.lock_outline_rounded,
          hint: 'Password baru',
          controller: _newPasswordController,
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          validator: _validateNewPassword,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          suffixIcon: _obscureSuffix(_obscureNew, () {
            setState(() => _obscureNew = !_obscureNew);
          }),
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.lock_outline_rounded,
          hint: 'Konfirmasi password baru',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSubmit(),
          validator: _validateConfirmPassword,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          suffixIcon: _obscureSuffix(_obscureConfirm, () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          }),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: 22.5),
        _SubmitButton(
          busy: _isLoading,
          onPressed: _isLoading ? null : _handleSubmit,
        ),
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _obscureSuffix(bool obscure, VoidCallback onTap) {
    return IconButton(
      iconSize: 18,
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minHeight: 24, minWidth: 32),
      icon: Icon(
        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: const Color(0xFF94A3B8),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSuccessView() {
    final c = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 40,
              color: Color(0xFF10B981),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 22.5),
        Text(
          'Password berhasil diubah!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan masuk kembali dengan password baru Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: c.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22.5),
        SizedBox(
          height: 41.25,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Back to login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.tintNeutral,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  const _SubmitButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41.25,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor:
              const Color(0xFF2563EB).withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Change password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
      ),
    );
  }
}

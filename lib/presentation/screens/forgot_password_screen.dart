// lib/presentation/screens/forgot_password_screen.dart
//
// Phase C2 of the SRS v2.0.0 audit (ignore/todo-srs.md).
//
// FR-004: Reset Password. Two states:
//   1. Form: ask for email, tap "Kirim link reset".
//   2. Success: confirmation screen telling the user to check
//      their inbox + "Kembali ke login" button.
//
// Calls `supabase.auth.resetPasswordForEmail()` which sends a
// one-time link. The user follows the link, lands on the
// redirect URL configured in Supabase Auth settings, and the
// actual password update happens there.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email harus diisi';
    final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('AuthRetryableFetchException: ', '');
      setState(() {
        _errorMessage = 'Gagal mengirim email reset: $msg';
        _isLoading = false;
      });
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
                  const Text(
                    'Lupa Password',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sent
                        ? 'Link reset telah dikirim ke email Anda'
                        : 'Masukkan email untuk menerima link reset password',
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
                    child: _sent
                        ? _buildSuccessView(isDark)
                        : _buildFormView(isDark),
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

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kami akan mengirim link untuk mengatur ulang password Anda ke email yang terdaftar.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
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
              onPressed: _isLoading ? null : _handleSend,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Kirim Link Reset'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(36),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 40,
            color: Color(0xFF43A047),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        const Text(
          'Email Terkirim!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kami telah mengirim link reset password ke:\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textMuted
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cek inbox atau folder spam Anda. Link akan kadaluarsa dalam 1 jam.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textMuted
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _sent = false;
              _errorMessage = null;
            });
          },
          child: const Text('Kirim ulang ke email lain'),
        ),
      ],
    );
  }
}
// lib/presentation/screens/forgot_password_screen.dart
//
// Forgot password screen.
// Two states:
//   1. Form: "Back to sign in" link + heading + email field +
//      "Send reset link" button.
//   2. Success: green checkmark + confirmation + "Back to login".
//
// Behaviour preserved from the previous version:
// - `supabase.auth.resetPasswordForEmail()` still does the work.
// - Email validation (regex) still gates submit.
// - Error banner appears below the field on network failures.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final email = _emailController.text.trim();
    if (_validateEmail(email) != null) {
      setState(() => _errorMessage = _validateEmail(email));
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .resetPassword(email);
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
          "Enter the email tied to your Helpdesk account and we'll "
          'send you a reset link.',
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
          hint: 'you@company.id',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSend(),
          validator: _validateEmail,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: 22.5),
        _SendButton(
          busy: _isLoading,
          onPressed: _isLoading ? null : _handleSend,
        ),
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.05);
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
              // Low-alpha brand-blue tint — reads OK on both
              // surfaceCard (light) and surface (dark).
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 40,
              color: Color(0xFF2563EB), // brand blue, fixed
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 22.5),
        Text(
          'Email Terkirim!',
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
          'Kami telah mengirim link reset password ke:\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: c.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cek inbox atau folder spam Anda. Link akan kadaluarsa dalam 1 jam.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
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
              backgroundColor: const Color(0xFF2563EB), // brand blue, fixed
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
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _sent = false;
                _errorMessage = null;
              });
            },
            child: Text(
              'Kirim ulang ke email lain',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB), // brand blue, fixed
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
        // Error banner bg flips: pale-red tint in light mode
        // (#FEF2F2), tintNeutral in dark mode so the brand red
        // icon + text pop.
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
            color: Color(0xFFEF4444), // brand red, fixed
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444), // brand red, fixed
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

class _SendButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  const _SendButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41.25,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // brand blue, fixed
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
                'Send reset link',
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

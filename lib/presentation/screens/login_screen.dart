// lib/presentation/screens/login_screen.dart
// - Single "email + password" form (no role selector — demo
//   accounts are documented in README and the splash hint).
// - Page lives inside a rounded "auth surface" card so the design
//   matches the AuthLayout exactly.
// - Tokens live in AppColors.auth* so future auth screens
//   (register / forgot-password) stay consistent.
//
// Behaviour preserved from the previous version:
// - `username→email` resolution still happens in
//   `AuthRepositoryImpl.login` (so "user" / "helpdesk" / "admin"
//   all still work).
// - `UserInactiveException` is still surfaced to the user.
// - `forgot-password` and `register` routes still wired.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../providers/auth_provider.dart';
import '../theme/app_semantic.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final id = _usernameController.text.trim();
    final pw = _passwordController.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _errorMessage = 'Email dan password harus diisi');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(currentUserProvider.notifier);
      final success = await authNotifier.login(id, pw);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage =
            'Email atau password salah. Default password: "password".');
      }
    } on UserInactiveException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login gagal: $e';
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
          _buildLogo(),
          const SizedBox(height: 30),
          _buildHeading(),
          const SizedBox(height: 22.5),
          _buildForm(),
          const SizedBox(height: 40),
          _buildSpacer(),
        ],
      ),
    );
  }

  /// Pushes the bottom "Need an account?" link to the bottom of
  /// the available height on tall screens (matches the
  /// `flex-[1_0_0]` + `justify-end` on node 8071:1004).
  Widget _buildSpacer() {
    return _RegisterLink(
      busy: _isLoading,
      onTap: () => Navigator.pushNamed(context, '/register'),
    );
  }

  Widget _buildLogo() {
    final c = context.semantic;
    return Row(
      children: [
        Container(
          width: 37.5,
          height: 37.5,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB), // brand blue, fixed
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 7.5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Helpdesk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                letterSpacing: -0.16,
                height: 1.5,
              ),
            ),
            Text(
              'E-Ticketing System',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeading() {
    final c = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.52,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3.75),
        Text(
          'Sign in to manage and resolve support tickets.',
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          icon: Icons.alternate_email_rounded,
          hint: 'Email address',
          controller: _usernameController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.lock_outline_rounded,
          hint: 'Password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: context.semantic.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 7.5),
        _RememberForgotRow(
          rememberMe: _rememberMe,
          onRememberChanged: (v) => setState(() => _rememberMe = v ?? false),
          onForgotTap: _isLoading
              ? null
              : () => Navigator.pushNamed(context, '/forgot-password'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: 22.5),
        _SignInButton(
          busy: _isLoading,
          onPressed: _isLoading ? null : _handleLogin,
        ),
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}

/// Single-line input matching the "Field" component:
/// 41.25 px tall, white fill, 18 px corners, 1 px `#e5e7eb` border,
/// `_AuthField` was extracted to `widgets/auth_field.dart`
/// (2026-06-22) so it can be reused by register + forgot-password.

class _RememberForgotRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onForgotTap;

  const _RememberForgotRow({
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: Checkbox(
                value: rememberMe,
                onChanged: onRememberChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: c.textSecondary,
                  width: 1,
                ),
                activeColor: const Color(0xFF2563EB), // brand blue, fixed
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 7.5),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onForgotTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB), // brand blue, fixed
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
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
        // (#FEF2F2), tintNeutral in dark mode (low-key muted
        // surface) so the brand red icon + text pop.
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

class _SignInButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  const _SignInButton({required this.busy, required this.onPressed});

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
                'Sign In',
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

class _RegisterLink extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  const _RegisterLink({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Center(
      child: GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 12, height: 1.5),
            children: [
              TextSpan(
                text: 'Need an account? ',
                style: TextStyle(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const TextSpan(
                text: 'Register',
                style: TextStyle(
                  color: Color(0xFF2563EB), // brand blue, fixed
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../providers/auth_provider.dart';
import '../theme/app_semantic.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const _departments = <String>[
    'IT',
    'Finance',
    'HR',
    'Operations',
    'Marketing',
    'Sales',
    'Legal',
    'Customer Service',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password harus diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String _deriveUsername(String email) {
    final local = email.split('@').first.toLowerCase();
    if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(local) && local.length >= 3) {
      return local;
    }
    return 'user_${email.hashCode.toUnsigned(20).toRadixString(36)}';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() => _errorMessage =
          'Anda harus menyetujui Terms of Service dan Privacy Policy.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final user = await ref.read(currentUserProvider.notifier).register(
            RegisterParams(
              username: _deriveUsername(email),
              name: _nameController.text.trim(),
              email: email,
              password: _passwordController.text,
              role: UserRole.user,
              department: _departmentController.text.trim(),
            ),
          );

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage =
            'Pendaftaran gagal. Silakan coba lagi dengan data lain.');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('AuthRetryableFetchException: ', '');
      setState(() => _errorMessage = 'Pendaftaran gagal: $msg');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLogo(),
            const SizedBox(height: 22.5),
            _buildHeading(),
            const SizedBox(height: 22.5),
            _buildForm(),
            const SizedBox(height: 22.5),
            _buildTermsRow(),
            const SizedBox(height: 15),
            _buildCreateButton(),
            const SizedBox(height: 22.5),
            _buildDivider(),
            const SizedBox(height: 11.25),
            _buildSignInInstead(),
            const SizedBox(height: 22.5),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading() {
    final c = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
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
          'Submit and track IT support tickets across your organization.',
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
          icon: Icons.person_outline_rounded,
          hint: 'Full name',
          controller: _nameController,
          textInputAction: TextInputAction.next,
          validator: (v) => _required(v, 'Full name'),
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.alternate_email_rounded,
          hint: 'Work email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.phone_outlined,
          hint: 'Phone number (optional)',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (_) => null, // optional, no validation
        ),
        const SizedBox(height: 11.25),
        _DepartmentDropdown(
          value: _departmentController.text.isEmpty
              ? null
              : _departmentController.text,
          onChanged: (v) => setState(
              () => _departmentController.text = v ?? ''),
        ),
        const SizedBox(height: 11.25),
        AuthField(
          icon: Icons.lock_outline_rounded,
          hint: 'Create password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRegister(),
          validator: _validatePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
              color: context.semantic.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 11.25),
          _ErrorBanner(message: _errorMessage!),
        ],
      ],
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildTermsRow() {
    final c = context.semantic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.875),
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: _agreeToTerms
                    ? const Color(0xFF2563EB) // brand blue, fixed
                    : c.tintNeutral,
                border: Border.all(
                  color: _agreeToTerms
                      ? const Color(0xFF2563EB) // brand blue, fixed
                      : c.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(3.75),
              ),
              child: _agreeToTerms
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 9.375),
        Expanded(
          child: Wrap(
            children: [
              Text(
                'I agree to the ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of Service — placeholder link'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB), // brand blue, fixed
                    height: 1.5,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy Policy — placeholder link'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB), // brand blue, fixed
                    height: 1.5,
                  ),
                ),
              ),
              Text(
                '.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    final bool enabled =
        !_isLoading && _agreeToTerms && _passwordController.text.length >= 6;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.4,
      child: SizedBox(
        height: 41.25,
        child: ElevatedButton(
          onPressed: enabled ? _handleRegister : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB), // brand blue, fixed
            disabledBackgroundColor:
                const Color(0xFF2563EB), // brand blue, fixed
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: EdgeInsets.zero,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final c = context.semantic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: _Hairline()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11.25),
          child: Text(
            'ALREADY HAVE AN ACCOUNT?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
        ),
        const Expanded(child: _Hairline()),
      ],
    );
  }

  Widget _buildSignInInstead() {
    final c = context.semantic;
    return SizedBox(
      width: double.infinity,
      height: 41.25,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Sign in instead',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final c = context.semantic;
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Having trouble? ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact IT support — placeholder'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Contact IT support',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB), // brand blue, fixed
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _DepartmentDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Container(
      height: 41.25,
      decoration: BoxDecoration(
        // Subtle inset (Option A): tintNeutral bg + 1px border.
        color: c.tintNeutral,
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.25),
            child: Icon(Icons.business_outlined,
                size: 16, color: c.textSecondary),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(
                  'Department',
                  style: TextStyle(
                    fontSize: 15,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 12.25),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: c.textSecondary,
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: c.textPrimary,
                ),
                dropdownColor: c.tintNeutral,
                borderRadius: BorderRadius.circular(18),
                items: _RegisterScreenState._departments
                    .map((d) => DropdownMenuItem<String>(
                          value: d,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.25),
                            child: Text(d),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
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

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.semantic.border);
  }
}
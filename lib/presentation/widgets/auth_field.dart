// lib/presentation/widgets/auth_field.dart
//
// Single-line text field used by all auth screens (login,
// register, forgot-password) — matches the Figma "Field"
// component from node 8071:978 / 8071:1720.
//
// 41.25 px tall, white fill, 18 px corners, 1 px `#e5e7eb`
// border, leading icon at 16 px. Optional suffix icon (used for
// the password-visibility toggle on the login screen).

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41.25,
      decoration: BoxDecoration(
        color: AppColors.authFieldFill,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.25),
            child: Icon(icon, size: 16, color: AppColors.authHint),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              autocorrect: false,
              enableSuggestions: !obscureText,
              validator: validator,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.authFieldText,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: AppColors.authHint,
                  fontWeight: FontWeight.w400,
                ),
                // Disable the default validator space — the
                // container is a fixed 41.25 px, so any error
                // message would otherwise push it taller and
                // break the Figma layout.
                errorStyle: const TextStyle(
                  fontSize: 0,
                  height: 0,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          if (suffixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffixIcon,
            ),
        ],
      ),
    );
  }
}

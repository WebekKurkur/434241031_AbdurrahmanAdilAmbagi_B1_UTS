// lib/presentation/widgets/auth_field.dart
//
// Single-line text field used by all auth screens (login,
// register, forgot-password) — matches the Figma "Field"
// component from node 8071:978 / 8071:1720.
//
// 41.25 px tall, tintNeutral fill (Option A — subtle inset
// that reads as a field without the high-contrast white-on-
// lightgrey look), 18 px corners, 1 px semantic border, leading
// icon at 16 px. Optional suffix icon (used for the password-
// visibility toggle on the login screen).
//
// 2026-06-24: Now reads `context.semantic` so it flips with
// `Theme.of(context).brightness` (Phase 3 → completed).
//   - bg: tintNeutral (1-2% lighter than page in light mode /
//     6% lighter in dark mode — matches the admin user-list
//     search field change earlier today)
//   - border: c.border
//   - icon: c.textSecondary
//   - text: c.textPrimary
//   - hint: c.textSecondary

import 'package:flutter/material.dart';
import '../theme/app_semantic.dart';

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
    final c = context.semantic;
    return Container(
      height: 41.25,
      decoration: BoxDecoration(
        // Subtle inset (Option A): tintNeutral bg + 1px border.
        // Matches the admin user-list search field change.
        color: c.tintNeutral,
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.25),
            child: Icon(icon, size: 16, color: c.textSecondary),
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: c.textPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: c.textSecondary,
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

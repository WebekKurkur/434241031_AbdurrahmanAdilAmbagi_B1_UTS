// lib/presentation/widgets/auth_field.dart

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

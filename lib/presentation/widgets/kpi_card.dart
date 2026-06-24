// lib/presentation/widgets/kpi_card.dart
//
// Shared KPI cards — extracted from `dashboard_screen.dart` so
// other screens (e.g. profile) can render the same visual
// language without duplicating markup.
//
// Two variants:
//   * `KpiCardHero` — wide horizontal card (icon + label + big
//                      number, used as the lead metric)
//   * `KpiCardSmall` — vertical card (icon + big number + label,
//                      used in 2-up rows)
//
// Both share the same decoration tokens via `_kpiDecoration`:
//   - white surface, 1 px #e5e7eb border, 15 px radius
//   - 0x0F0F1115 shadow, blur 1, offset (0, 1)
//   - tinted icon container (12% of `tint` for the bg, full
//     `tint` for the icon)
//
// 2026-06-22: extracted from dashboard_screen.dart for reuse on
// the redesigned profile screen.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

BoxDecoration _kpiDecoration() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.authBorder),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F1115),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );

class KpiCardHero extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color tint;

  const KpiCardHero({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kpiDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.authHint,
                    height: 1.5,
                  ),
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authFieldText,
                    letterSpacing: -0.9,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KpiCardSmall extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color tint;

  const KpiCardSmall({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kpiDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(height: 11.25),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.authFieldText,
              letterSpacing: -0.48,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.authHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

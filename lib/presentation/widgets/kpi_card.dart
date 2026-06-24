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
// 2026-06-24: Phase 2 of the theme refactor (ignore/todo-theme.md).
// The shared decoration now reads `context.semantic` so cards flip
// with `Theme.of(context).brightness`. Tinted icon containers stay
// as-is (low-alpha overlays of brand colors read OK on both
// surfaces).

import 'package:flutter/material.dart';

import '../theme/app_semantic.dart';

BoxDecoration _kpiDecoration(BuildContext context) {
  final c = context.semantic;
  return BoxDecoration(
    color: c.surfaceCard,
    border: Border.all(color: c.border),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: c.shadow,
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

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
    final c = context.semantic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kpiDecoration(context),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
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
    final c = context.semantic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _kpiDecoration(context),
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.48,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/widgets/shimmer_card.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F8);
    final highlightColor = isDark ? const Color(0xFF2D3F55) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box(60, 10),
                _box(70, 22, radius: 20),
              ],
            ),
            const SizedBox(height: 12),
            _box(double.infinity, 16),
            const SizedBox(height: 8),
            _box(200, 13),
            const SizedBox(height: 12),
            _box(150, 13),
            const SizedBox(height: 14),
            Row(
              children: [
                _box(70, 22, radius: 6),
                const Spacer(),
                _box(80, 13),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F8);
    final highlightColor = isDark ? const Color(0xFF2D3F55) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 12),
            Container(width: 40, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(width: 70, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

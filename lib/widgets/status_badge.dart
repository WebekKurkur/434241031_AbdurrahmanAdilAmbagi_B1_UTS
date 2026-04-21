// lib/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final TicketStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final bgColor = getStatusBgColor(status);
    final label = getStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/widgets/ticket_list_card.dart
//
// Figma 8071:1238 ticket card. Used by:
//   - dashboard_screen.dart recent activity
//   - ticket_list_screen.dart main list
//
// Pure widget: takes a `TicketEntity` + `onTap`. No providers.
// Lays out per Figma spec:
//   - 15 px radius, 1 px #e5e7eb border, 6 % drop-shadow (0,1,blur 1)
//   - 16 px padding, columns: status-dot row → title (7.5 pt) →
//     description (3.75 pt) → footer row (11.25 pt)
//   - Status dot colour follows TicketStatus
//   - Right-aligned status pill in row 1, comment icon+count in
//     footer

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ticket_entity.dart';
import '../theme/app_theme.dart';

class TicketListCard extends StatelessWidget {
  final TicketEntity ticket;
  final VoidCallback onTap;
  const TicketListCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  Color _statusDotColor() => getStatusColor(ticket.status);

  Color _categoryColor() {
    switch (ticket.category.toLowerCase()) {
      case 'hardware':
        return const Color(0xFFEF4444);
      case 'software':
        return const Color(0xFFF59E0B);
      case 'network':
        return AppColors.authPrimary;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _ticketCode() {
    if (ticket.id.toUpperCase().startsWith('TKT-')) return ticket.id;
    if (ticket.id.length > 8) return ticket.id;
    return 'TKT-${ticket.id}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusDotColor();
    final dateLabel = DateFormat('d MMM').format(ticket.createdAt);
    final commentsCount = ticket.comments.length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: dot + TKT-XXX | status pill
            Row(
              children: [
                Container(
                  width: 7.5,
                  height: 7.5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7.5),
                Text(
                  _ticketCode(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authHint,
                    letterSpacing: 0.44,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                _StatusPill(
                  label: getStatusLabel(ticket.status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 7.5),
            // Title (single line, ellipsised)
            Text(
              ticket.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.authFieldText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3.75),
            // Description (single line, ellipsised)
            Text(
              ticket.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.authHint,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 11.25),
            // Footer row: category · date | comments
            Row(
              children: [
                Text(
                  ticket.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _categoryColor(),
                    height: 1.5,
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width: 3.75,
                  height: 3.75,
                  decoration: const BoxDecoration(
                    color: AppColors.authBorder,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authHint,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 12,
                      color: AppColors.authHint,
                    ),
                    const SizedBox(width: 5.625),
                    Text(
                      '$commentsCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.authHint,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9.375,
        vertical: 1.875,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(33554400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.625,
            height: 5.625,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.625),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.06,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
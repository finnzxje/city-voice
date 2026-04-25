import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reports/models/report.dart';

/// Card showing reporter, assignee, priority, and zone details.
class DetailsListCard extends StatelessWidget {
  final Report report;

  const DetailsListCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -20, 0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person,
            iconColor: const Color(0xFF0044CC),
            label: 'NGƯỜI BÁO CÁO',
            value: report.citizenName ?? 'Ẩn danh',
          ),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _DetailRow(
            icon: Icons.manage_accounts,
            iconColor: const Color(0xFF4B5563),
            label: 'PHỤ TRÁCH',
            value: report.assignedToName ?? 'Chưa phân công',
          ),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _DetailRow(
            icon: Icons.flag,
            iconColor: AppColors.priorityColor(report.priority),
            label: 'ĐỘ ƯU TIÊN',
            value: report.priorityLabel ?? 'Chưa rõ',
            valueColor: AppColors.priorityColor(report.priority),
          ),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _DetailRow(
            icon: Icons.location_on,
            iconColor: const Color.fromARGB(255, 15, 148, 59),
            label: 'KHU VỰC',
            value: report.administrativeZoneName ?? 'Chưa rõ',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

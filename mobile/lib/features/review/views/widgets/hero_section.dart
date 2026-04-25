import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/utils.dart';
import '../../../reports/models/report.dart';

/// Hero image with floating status badge and date badge.
class HeroSection extends StatelessWidget {
  final Report report;

  const HeroSection({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(report.currentStatus);

    return Stack(
      children: [
        // Image
        SizedBox(
          height: 280,
          width: double.infinity,
          child: report.incidentImageUrl != null
              ? Image.network(
                  Utils.getSafeUrl(report.incidentImageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFE5E7EB)),
                )
              : Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 48, color: Color(0xFF9CA3AF)),
                  ),
                ),
        ),
        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFF8F9FA).withOpacity(1.0),
                  const Color(0xFFF8F9FA).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // ── Top Left Tag (Status Only) ──
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusBackgroundColor(report.currentStatus),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              report.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // ── Top Right Date Badge ──
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Color(0xFF0033CC)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(report.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

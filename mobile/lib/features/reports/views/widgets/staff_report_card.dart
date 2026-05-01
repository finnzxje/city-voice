import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_cached_network_image.dart';
import '../../../../core/utils/utils.dart';
import '../../models/report.dart';

/// Horizontal report card used in the staff dashboard.
class StaffHorizontalReportCard extends StatelessWidget {
  final Report report;

  const StaffHorizontalReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(report.currentStatus);
    final statusBg = AppColors.statusBackgroundColor(report.currentStatus);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) {
              unawaited(
                precacheAppNetworkImage(
                  context,
                  Utils.getSafeUrl(report.incidentImageUrl),
                  memCacheWidth: 1200,
                ),
              );
            },
            onTap: () => context.push('/staff-reports/${report.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image & Priority Tag Stack ──
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppCachedNetworkImage(
                        imageUrl: Utils.getSafeUrl(report.incidentImageUrl),
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        placeholder: _buildPlaceholderImage(),
                        errorWidget: _buildPlaceholderImage(),
                      ),

                      // Priority Tag
                      if (report.priority != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.priorityColor(report.priority)
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              report.priorityLabel?.toUpperCase() ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Resolved checkmark
                      if (report.currentStatus == 'resolved')
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A6B63),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Content Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time & Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                color: Color(0xFF0044CC),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                report.statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          report.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          report.description ??
                              report.citizenName ??
                              'Không có mô tả',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),

                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            report.categoryName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFEBF0FF),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Color(0xFFB0C4DE),
          size: 48,
        ),
      ),
    );
  }
}

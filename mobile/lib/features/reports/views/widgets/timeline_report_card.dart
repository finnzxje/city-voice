import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_cached_network_image.dart';
import '../../../../core/utils/utils.dart';
import '../../models/report.dart';

/// Timeline-style report card for the citizen dashboard.
class TimelineReportCard extends StatelessWidget {
  static const double _timelineColumnWidth = 30;
  static const double _timelineContentSpacing = 42;

  final Report report;
  final bool showDate;
  final bool isLast;

  const TimelineReportCard({
    super.key,
    required this.report,
    required this.showDate,
    required this.isLast,
  });

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'HÔM NAY';
    }
    return '${date.day} THÁNG ${date.month}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(report.currentStatus);
    final statusBg = AppColors.statusBackgroundColor(report.currentStatus);

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _timelineColumnWidth,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedLinePainter(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    isLast: isLast,
                    startInset: showDate ? 16 : 0,
                  ),
                ),
              ),
              if (showDate)
                Positioned(
                  top: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      color: AppColors.background,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _timelineContentSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDate) ...[
                Text(
                  _formatDateHeader(report.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              GestureDetector(
                onTapDown: (_) {
                  unawaited(
                    precacheAppNetworkImage(
                      context,
                      Utils.getSafeUrl(report.incidentImageUrl),
                      memCacheWidth: 1200,
                    ),
                  );
                },
                onTap: () => context.push('/reports/${report.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: AppCachedNetworkImage(
                              imageUrl:
                                  Utils.getSafeUrl(report.incidentImageUrl),
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                              placeholder: _buildPlaceholderImage(),
                              errorWidget: _buildPlaceholderImage(),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    switch (report.currentStatus) {
                                      'newly_received' =>
                                        Icons.star_border_outlined,
                                      'in_progress' =>
                                        Icons.access_time_outlined,
                                      'resolved' =>
                                        Icons.check_circle_outline_outlined,
                                      'rejected' => Icons.cancel_outlined,
                                      _ => Icons.fiber_new_rounded,
                                    },
                                    size: 12,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    report.statusLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Text Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.label_rounded,
                                  size: 14,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    report.categoryName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              report.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.description ?? 'Không có mô tả chi tiết.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 140,
      color: const Color(0xFF4A7C75),
      child: const Center(
        child: Text(
          'INCIDENT',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

/// Custom dashed line painter for the timeline.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final bool isLast;
  final double startInset;
  late final Paint _paint = Paint()
    ..color = color
    ..strokeWidth = 1.5;

  _DashedLinePainter({
    required this.color,
    required this.isLast,
    required this.startInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    var startY = startInset;
    final endY = isLast ? size.height - 40 : size.height;

    while (startY < endY) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        _paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/stats_model.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Row of status count chips.
class StatusBreakdown extends StatelessWidget {
  const StatusBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<AnalyticsViewModel,
        ({AnalyticsViewState statsState, StatsModel? stats})>(
      (vm) => (
        statsState: vm.statsState,
        stats: vm.stats,
      ),
    );
    final stats = state.stats;

    if (stats == null && state.statsState == AnalyticsViewState.loading) {
      return const SizedBox(height: 36);
    }
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        _StatusChip('Mới', stats.newlyReceived, AppColors.statusNew),
        const SizedBox(width: 8),
        _StatusChip('Đang xử lý', stats.inProgress, AppColors.statusInProgress),
        const SizedBox(width: 8),
        _StatusChip('Đã xử lý', stats.resolved, AppColors.statusResolved),
        const SizedBox(width: 8),
        _StatusChip('Từ chối', stats.rejected, AppColors.statusRejected),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

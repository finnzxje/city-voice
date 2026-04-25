import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Row of three score cards.
class ScorecardsRow extends StatelessWidget {
  final AnalyticsViewModel vm;

  const ScorecardsRow({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.statsState == AnalyticsViewState.loading && vm.stats == null) {
      return Row(
        children: [
          Expanded(child: _buildSingleShimmer()),
          const SizedBox(width: 8),
          Expanded(child: _buildSingleShimmer()),
          const SizedBox(width: 8),
          Expanded(child: _buildSingleShimmer()),
        ],
      );
    }

    final stats = vm.stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            label: 'Tổng số\nbáo cáo',
            value: '${stats.totalReports}',
            icon: Icons.description_outlined,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScoreCard(
            label: 'Tỉ lệ\nthành công',
            value: '${stats.completionRate.toStringAsFixed(1)}%',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScoreCard(
            label: 'Thời gian\nxử lý TB',
            value: '${stats.averageResolutionHours.toStringAsFixed(1)}h',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ScoreCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

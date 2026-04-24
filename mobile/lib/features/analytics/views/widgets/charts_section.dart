import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/stats_model.dart';
import '../../viewmodels/analytics_view_model.dart';
import 'error_retry_widget.dart';

/// Section containing category pie chart, priority bar chart, and zone chart.
class ChartsSection extends StatelessWidget {
  const ChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<
        AnalyticsViewModel,
        ({
          AnalyticsViewState statsState,
          String? statsError,
          StatsModel? stats,
        })>(
      (vm) => (
        statsState: vm.statsState,
        statsError: vm.statsError,
        stats: vm.stats,
      ),
    );
    final analyticsViewModel = context.read<AnalyticsViewModel>();

    if (state.statsState == AnalyticsViewState.error) {
      return ErrorRetryWidget(
        message: state.statsError ?? 'Lỗi tải dữ liệu',
        onRetry: analyticsViewModel.loadDashboard,
      );
    }

    final stats = state.stats;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _ChartCard(
          title: 'Theo danh mục',
          child: _CategoryPieChart(data: stats.byCategory),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Theo mức độ ưu tiên',
          child: _PriorityBarChart(data: stats.byPriority),
        ),
        const SizedBox(height: 16),
        if (stats.byZone.isNotEmpty)
          _ChartCard(
            title: 'Theo quận/khu vực',
            child: _ZoneBarChart(data: stats.byZone),
          ),
      ],
    );
  }
}

// ─── Chart Card Container ────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Pie Chart: by Category ──────────────────────────────────────────────────

class _CategoryPieChart extends StatelessWidget {
  final Map<String, int> data;

  const _CategoryPieChart({required this.data});

  static const _colors = [
    Color(0xFF0D6E6E),
    Color(0xFFFF8F00),
    Color(0xFF5C6BC0),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
            child: Text('Không có dữ liệu',
                style: TextStyle(color: AppColors.textHint))),
      );
    }

    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: entries.asMap().entries.map((mapEntry) {
                final i = mapEntry.key;
                final e = mapEntry.value;
                final pct = total > 0 ? (e.value / total * 100) : 0.0;
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: _colors[i % _colors.length],
                  radius: 50,
                  title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final e = mapEntry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key} (${e.value})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Bar Chart: by Priority ──────────────────────────────────────────────────

class _PriorityBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _PriorityBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final order = ['critical', 'high', 'medium', 'low'];
    final labels = {
      'critical': 'Nghiêm trọng',
      'high': 'Cao',
      'medium': 'Trung bình',
      'low': 'Thấp',
    };
    final colors = {
      'critical': const Color(0xFFEF4444),
      'high': const Color(0xFFF97316),
      'medium': const Color(0xFFFBBF24),
      'low': const Color(0xFF3B82F6),
    };

    final maxVal = data.values.fold<int>(0, max).toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal > 0 ? maxVal * 1.35 : 10,
          barGroups: order.asMap().entries.map((entry) {
            final i = entry.key;
            final key = entry.value;
            final val = (data[key] ?? 0).toDouble();
            return BarChartGroupData(
              x: i,
              showingTooltipIndicators: [0],
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: colors[key] ?? AppColors.textHint,
                  width: 36,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= order.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[order[idx]] ?? order[idx],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              tooltipMargin: 4,
              getTooltipColor: (_) => Colors.transparent,
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}',
                  TextStyle(
                    color: colors[order[groupIdx]] ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List-style Zone Chart ───────────────────────────────────────────────────

class _ZoneBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _ZoneBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isEmpty ? 1 : entries.first.value;

    return Column(
      children: entries.map((e) {
        final fraction = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction.clamp(0.02, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 32,
                child: Text(
                  '${e.value}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

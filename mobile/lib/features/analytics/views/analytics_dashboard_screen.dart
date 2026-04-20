import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../reports/models/incident_category.dart';
import '../../reports/services/category_service.dart';
import '../models/analytics_filter.dart';
import '../viewmodels/analytics_view_model.dart';

/// Full-featured analytics dashboard for managers and admins.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Báo cáo & Phân tích'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        actions: [
          Consumer<AnalyticsViewModel>(
            builder: (context, vm, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined),
                    tooltip: 'Bộ lọc',
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (vm.activeFilter.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AnalyticsViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            onRefresh: vm.loadDashboard,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 2: Scorecards
                  _ScorecardsRow(vm: vm),
                  const SizedBox(height: 20),

                  // Section 3: Status breakdown
                  _StatusBreakdown(vm: vm),
                  const SizedBox(height: 24),

                  // Section 4: Charts
                  _ChartsSection(vm: vm),
                  const SizedBox(height: 24),

                  // Section 5: Heatmap
                  _HeatmapSection(vm: vm),
                  const SizedBox(height: 24),

                  // Section 6: Export actions
                  _ExportSection(vm: vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final vm = context.read<AnalyticsViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: _FilterSheet(
          currentFilter: vm.activeFilter,
          categoryService: context.read<CategoryService>(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 2: Scorecards
// ═══════════════════════════════════════════════════════════════════════════════

class _ScorecardsRow extends StatelessWidget {
  final AnalyticsViewModel vm;

  const _ScorecardsRow({required this.vm});

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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 3: Status Breakdown
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBreakdown extends StatelessWidget {
  final AnalyticsViewModel vm;

  const _StatusBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final stats = vm.stats;
    if (stats == null && vm.statsState == AnalyticsViewState.loading) {
      return const SizedBox(height: 36);
    }
    if (stats == null) return const SizedBox.shrink();

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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 4: Charts
// ═══════════════════════════════════════════════════════════════════════════════

class _ChartsSection extends StatelessWidget {
  final AnalyticsViewModel vm;

  const _ChartsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.statsState == AnalyticsViewState.error) {
      return _ErrorRetryWidget(
        message: vm.statsError ?? 'Lỗi tải dữ liệu',
        onRetry: vm.loadDashboard,
      );
    }

    final stats = vm.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Chart A: Pie chart — by category
        _ChartCard(
          title: 'Theo danh mục',
          child: _CategoryPieChart(data: stats.byCategory),
        ),
        const SizedBox(height: 16),

        // Chart B: Bar chart — by priority
        _ChartCard(
          title: 'Theo mức độ ưu tiên',
          child: _PriorityBarChart(data: stats.byPriority),
        ),
        const SizedBox(height: 16),

        // Chart C: Horizontal bar — by zone (top 8)
        if (stats.byZone.isNotEmpty)
          _ChartCard(
            title: 'Theo quận/khu vực',
            child: _ZoneBarChart(data: stats.byZone),
          ),
      ],
    );
  }
}

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

// ── Pie Chart: by Category ───────────────────────────────────────────────────

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
        // Legend
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

// ── Bar Chart: by Priority ───────────────────────────────────────────────────

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
      'critical': const Color(0xFFEF4444), // red
      'high': const Color(0xFFF97316), // orange
      'medium': const Color(0xFFFBBF24), // yellow
      'low': const Color(0xFF3B82F6), // blue
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

// ── List-style Zone Chart ────────────────────────────────────────────────────

class _ZoneBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _ZoneBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Sort descending, show all.
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
              // Zone name (left)
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
              // Horizontal bar
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
              // Count (right)
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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 5: Heatmap
// ═══════════════════════════════════════════════════════════════════════════════

class _HeatmapSection extends StatelessWidget {
  final AnalyticsViewModel vm;

  const _HeatmapSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bản đồ nhiệt sự cố',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 320,
            child: _buildMapContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    if (vm.heatmapState == AnalyticsViewState.loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      );
    }

    if (vm.heatmapState == AnalyticsViewState.error) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 40, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(vm.heatmapError ?? 'Lỗi tải bản đồ',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // HCMC center.
    const center = LatLng(10.7769, 106.7009);

    return FlutterMap(
      options: const MapOptions(
        initialCenter: center,
        initialZoom: 11,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'vn.cityvoice.mobile',
        ),
        CircleLayer(
          circles: vm.heatmapPoints.map((pt) {
            return CircleMarker(
              point: LatLng(pt.latitude, pt.longitude),
              radius: 12,
              color: _priorityColor(pt.priority),
              borderStrokeWidth: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _priorityColor(String priority) {
    return switch (priority) {
      'critical' => Colors.red.withValues(alpha: 0.6),
      'high' => Colors.orange.withValues(alpha: 0.5),
      'medium' => Colors.amber.withValues(alpha: 0.4),
      'low' => Colors.blue.withValues(alpha: 0.35),
      _ => Colors.grey.withValues(alpha: 0.3),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 6: Export Actions
// ═══════════════════════════════════════════════════════════════════════════════

class _ExportSection extends StatelessWidget {
  final AnalyticsViewModel vm;

  const _ExportSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isLoading = vm.exportState == AnalyticsViewState.loading;

    // Show snackbar on export error.
    if (vm.exportState == AnalyticsViewState.error && vm.exportError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.exportError!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        vm.clearExportState();
      });
    }

    // Show snackbar on export success.
    if (vm.exportState == AnalyticsViewState.success &&
        vm.lastExportedPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xuất file thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        vm.clearExportState();
      });
    }

    final isLoadingExcel = isLoading && vm.exportType == 'excel';
    final isLoadingPdf = isLoading && vm.exportType == 'pdf';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => vm.exportExcel(),
            icon: isLoadingExcel
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF217346),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => vm.exportPdf(),
            icon: isLoadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR / RETRY WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetryWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppColors.error),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  final AnalyticsFilter currentFilter;
  final CategoryService categoryService;

  const _FilterSheet({
    required this.currentFilter,
    required this.categoryService,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _from;
  late String? _to;
  late int? _categoryId;
  late String? _priority;

  List<IncidentCategory> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _from = widget.currentFilter.from;
    _to = widget.currentFilter.to;
    _categoryId = widget.currentFilter.categoryId;
    _priority = widget.currentFilter.priority;

    _loadCategories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await widget.categoryService.getCategories();
    } catch (_) {}
    if (mounted) setState(() => _loadingCategories = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Từ ngày',
                      value: _from,
                      onPicked: (d) => setState(() => _from = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Đến ngày',
                      value: _to,
                      onPicked: (d) => setState(() => _to = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                DropdownButtonFormField<int?>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    ..._categories.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              const SizedBox(height: 16),

              // Priority dropdown
              DropdownButtonFormField<String?>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(
                      value: 'critical', child: Text('Nghiêm trọng')),
                  DropdownMenuItem(value: 'high', child: Text('Cao')),
                  DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                  DropdownMenuItem(value: 'low', child: Text('Thấp')),
                ],
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final vm = context.read<AnalyticsViewModel>();
                        vm.resetFilter();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final vm = context.read<AnalyticsViewModel>();
                        vm.applyFilter(AnalyticsFilter(
                          from: _from,
                          to: _to,
                          categoryId: _categoryId,
                          priority: _priority,
                        ));
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Field Helper ────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onPicked(null),
              )
            : const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      controller: TextEditingController(text: value ?? ''),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null
              ? DateTime.tryParse(value!) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onPicked(formatted);
        }
      },
    );
  }
}

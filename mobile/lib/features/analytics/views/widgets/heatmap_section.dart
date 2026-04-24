import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_map_tile_layer.dart';
import '../../models/heatmap_point.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Heatmap section with map overlay.
class HeatmapSection extends StatelessWidget {
  const HeatmapSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<
        AnalyticsViewModel,
        ({
          AnalyticsViewState heatmapState,
          String? heatmapError,
          List<HeatmapPoint> heatmapPoints,
        })>(
      (vm) => (
        heatmapState: vm.heatmapState,
        heatmapError: vm.heatmapError,
        heatmapPoints: vm.heatmapPoints,
      ),
    );

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
            child: _buildMapContent(
              heatmapState: state.heatmapState,
              heatmapError: state.heatmapError,
              heatmapPoints: state.heatmapPoints,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent({
    required AnalyticsViewState heatmapState,
    required String? heatmapError,
    required List<HeatmapPoint> heatmapPoints,
  }) {
    if (heatmapState == AnalyticsViewState.loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      );
    }

    if (heatmapState == AnalyticsViewState.error) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 40, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(heatmapError ?? 'Lỗi tải bản đồ',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

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
        const AppMapTileLayer(),
        CircleLayer(
          circles: [
            for (final point in heatmapPoints)
              CircleMarker(
                point: LatLng(point.latitude, point.longitude),
                radius: 12,
                color: _priorityColor(point.priority),
                borderStrokeWidth: 0,
              ),
          ],
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Heatmap section with map overlay.
class HeatmapSection extends StatelessWidget {
  final AnalyticsViewModel vm;

  const HeatmapSection({super.key, required this.vm});

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

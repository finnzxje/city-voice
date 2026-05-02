import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_map_tile_layer.dart';
import '../../../../core/widgets/report_location_map_screen.dart';
import '../../../reports/models/report.dart';

/// Mini map preview with an "Open Map" button.
class ReportMapSection extends StatelessWidget {
  final Report report;

  const ReportMapSection({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final markerLocation = LatLng(report.latitude, report.longitude);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ReportLocationMapScreen.open(
            context,
            latitude: report.latitude,
            longitude: report.longitude,
            coordinatesText: report.coordinatesText,
            locationName: report.administrativeZoneName,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AbsorbPointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: markerLocation,
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          const AppMapTileLayer(),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: markerLocation,
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.error,
                                  size: 56,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 68,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.textPrimary.withValues(alpha: 0.55),
                              AppColors.textPrimary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Chạm để mở bản đồ',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TỌA ĐỘ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.coordinatesText,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

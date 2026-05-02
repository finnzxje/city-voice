import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../utils/app_map_tile_layer.dart';

class ReportLocationMapScreen extends StatelessWidget {
  const ReportLocationMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.coordinatesText,
    this.locationName,
  });

  final double latitude;
  final double longitude;
  final String coordinatesText;
  final String? locationName;

  static Future<void> open(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String coordinatesText,
    String? locationName,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ReportLocationMapScreen(
          latitude: latitude,
          longitude: longitude,
          coordinatesText: coordinatesText,
          locationName: locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markerLocation = LatLng(latitude, longitude);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface.withValues(alpha: 0),
        title: Text(
          'Xem vị trí báo cáo',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openGoogleMaps(context),
            tooltip: 'Mở Google Maps',
            icon: const Icon(
              Icons.directions_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: markerLocation,
              initialZoom: 17,
              minZoom: 5,
              maxZoom: 19,
            ),
            children: [
              const AppMapTileLayer(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: markerLocation,
                    width: 56,
                    height: 56,
                    child: const Icon(
                      Icons.location_on,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _ReportLocationMapSummary(
                coordinatesText: coordinatesText,
                locationName: _resolvedLocationName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _resolvedLocationName {
    final currentLocationName = locationName?.trim();
    if (currentLocationName == null || currentLocationName.isEmpty) {
      return 'Hồ Chí Minh';
    }

    return currentLocationName;
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final didLaunch = await launchUrl(
      _googleMapsUri,
      mode: LaunchMode.externalApplication,
    );
    if (didLaunch || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể mở Google Maps trên thiết bị này.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Uri get _googleMapsUri {
    return Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{
        'api': '1',
        'query': '$latitude,$longitude',
      },
    );
  }
}

class _ReportLocationMapSummary extends StatelessWidget {
  const _ReportLocationMapSummary({
    required this.coordinatesText,
    required this.locationName,
  });

  final String coordinatesText;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MapSummaryIcon(
                  icon: Icons.place_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khu vực',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationName,
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
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              color: AppColors.divider,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const _MapSummaryIcon(
                  icon: Icons.my_location_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tọa độ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coordinatesText,
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
          ],
        ),
      ),
    );
  }
}

class _MapSummaryIcon extends StatelessWidget {
  const _MapSummaryIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
      ),
    );
  }
}

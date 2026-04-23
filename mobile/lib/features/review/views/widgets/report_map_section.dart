import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_map_tile_layer.dart';
import '../../../reports/models/report.dart';

/// Mini map preview with an "Open Map" button.
class ReportMapSection extends StatelessWidget {
  final Report report;

  const ReportMapSection({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              // Map
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(report.latitude, report.longitude),
                  initialZoom: 16.0,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  const AppMapTileLayer(),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(report.latitude, report.longitude),
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_on,
                          color: Color(0xFFE53E3E), size: 56),
                    ),
                  ]),
                ],
              ),
              // Dark gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // "MỞ BẢN ĐỒ" Button
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.map, size: 14, color: Color(0xFF0033CC)),
                      SizedBox(width: 6),
                      Text(
                        'MỞ BẢN ĐỒ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
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
    );
  }
}

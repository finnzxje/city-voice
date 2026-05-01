import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared tile layer config for flutter_map surfaces.
class AppMapTileLayer extends StatelessWidget {
  const AppMapTileLayer({
    super.key,
    this.urlTemplate = _defaultUrlTemplate,
    this.userAgentPackageName = _defaultUserAgentPackageName,
    this.panBuffer = 1,
    this.keepBuffer = 2,
  });

  static const String _defaultUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _defaultUserAgentPackageName = 'com.example.city_voice';

  final String urlTemplate;
  final String userAgentPackageName;
  final int panBuffer;
  final int keepBuffer;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
      panBuffer: panBuffer,
      keepBuffer: keepBuffer,
      tileDisplay: const TileDisplay.instantaneous(),
    );
  }
}

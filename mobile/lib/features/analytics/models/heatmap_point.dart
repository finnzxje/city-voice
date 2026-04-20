/// A single geo-tagged heatmap point from `GET /analytics/heatmap`.
class HeatmapPoint {
  final double latitude;
  final double longitude;
  final String priority;
  final String category;

  const HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.category,
  });

  factory HeatmapPoint.fromJson(Map<String, dynamic> json) {
    return HeatmapPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      priority: json['priority'] as String? ?? 'low',
      category: json['category'] as String? ?? '',
    );
  }
}

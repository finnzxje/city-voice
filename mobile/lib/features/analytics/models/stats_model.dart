/// Aggregated statistics from `GET /analytics/stats`.
class StatsModel {
  final int totalReports;
  final int newlyReceived;
  final int inProgress;
  final int resolved;
  final int rejected;
  final double completionRate;
  final double averageResolutionHours;
  final Map<String, int> byCategory;
  final Map<String, int> byPriority;
  final Map<String, int> byZone;

  const StatsModel({
    required this.totalReports,
    required this.newlyReceived,
    required this.inProgress,
    required this.resolved,
    required this.rejected,
    required this.completionRate,
    required this.averageResolutionHours,
    required this.byCategory,
    required this.byPriority,
    required this.byZone,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalReports: json['totalReports'] as int? ?? 0,
      newlyReceived: json['newlyReceived'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageResolutionHours:
          (json['averageResolutionHours'] as num?)?.toDouble() ?? 0.0,
      byCategory: _toIntMap(json['byCategory']),
      byPriority: _toIntMap(json['byPriority']),
      byZone: _toIntMap(json['byZone']),
    );
  }

  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    }
    return {};
  }
}

/// Incident report model for citizen-facing views.
///
/// Maps to backend `ReportResponse` with 20+ fields.
class Report {
  final String id;
  final String title;
  final String? description;
  final int? categoryId;
  final String categoryName;
  final double latitude;
  final double longitude;
  final String? administrativeZoneName;
  final String? incidentImageUrl;
  final String? resolutionImageUrl;
  final String currentStatus;
  final String? priority;
  final String? citizenId;
  final String? citizenName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const Report({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.categoryName,
    required this.latitude,
    required this.longitude,
    this.administrativeZoneName,
    this.incidentImageUrl,
    this.resolutionImageUrl,
    required this.currentStatus,
    this.priority,
    this.citizenId,
    this.citizenName,
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      administrativeZoneName: json['administrativeZoneName'] as String?,
      incidentImageUrl: json['incidentImageUrl'] as String?,
      resolutionImageUrl: json['resolutionImageUrl'] as String?,
      currentStatus: json['currentStatus'] as String? ?? 'newly_received',
      priority: json['priority'] as String?,
      citizenId: json['citizenId'] as String? ?? '',
      citizenName: json['citizenName'] as String?,
      assignedToId: json['assignedToId'] as String?,
      assignedToName: json['assignedToName'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
      resolvedAt: _parseDateTime(json['resolvedAt']),
    );
  }

  /// Parses ISO 8601 / OffsetDateTime strings from the backend.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return null;
      }
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }
    return null;
  }

  // ── Convenience getters ──────────────────────────────────────────────────

  /// Human-readable Vietnamese status label.
  String get statusLabel {
    return switch (currentStatus) {
      'newly_received' => 'Mới tiếp nhận',
      'in_progress' => 'Đang xử lý',
      'resolved' => 'Đã giải quyết',
      'rejected' => 'Bị từ chối',
      _ => currentStatus,
    };
  }

  /// Human-readable priority label.
  String? get priorityLabel {
    return switch (priority) {
      'low' => 'Thấp',
      'medium' => 'Trung bình',
      'high' => 'Cao',
      'critical' => 'Nghiêm trọng',
      _ => priority,
    };
  }
}

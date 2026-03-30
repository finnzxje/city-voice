/// In-app notification model.
///
/// Maps to backend `NotificationResponse`.
class NotificationModel {
  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String? reportId;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.sentAt,
    required this.createdAt,
    this.reportId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      sentAt: _parseDate(json['sentAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      reportId: json['reportId'] as String?,
    );
  }

  /// The best date to display (prefer sentAt, fall back to createdAt).
  DateTime get displayDate => sentAt ?? createdAt;

  /// Returns a copy with the specified field(s) changed.
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      message: message,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      createdAt: createdAt,
      reportId: reportId,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

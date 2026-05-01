import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_payload_parser.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const int _defaultMarkAsReadChunkSize = 8;

  final Dio _dio;

  NotificationService({required Dio dio}) : _dio = dio;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    return ApiPayloadParser.parseList(
      response.data,
      fromJson: NotificationModel.fromJson,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.unreadCount);
    return ApiPayloadParser.parseValue<int>(
      response.data,
      parser: (payload) {
        if (payload is int) return payload;
        if (payload is num) return payload.toInt();
        if (payload is String) return int.tryParse(payload) ?? 0;
        if (payload is Map<String, dynamic>) {
          final count = payload['count'];
          if (count is int) return count;
          if (count is num) return count.toInt();
          if (count is String) return int.tryParse(count) ?? 0;
        }
        return 0;
      },
    );
  }

  Future<void> markAsRead(String id) async {
    await _dio.put(ApiConstants.markNotificationRead(id));
  }

  Future<void> markAllAsRead(
    List<String> notificationIds, {
    int chunkSize = _defaultMarkAsReadChunkSize,
  }) async {
    if (notificationIds.isEmpty) {
      return;
    }

    for (var start = 0; start < notificationIds.length; start += chunkSize) {
      final end = start + chunkSize < notificationIds.length
          ? start + chunkSize
          : notificationIds.length;
      final chunk = notificationIds.sublist(start, end);
      await Future.wait(chunk.map(markAsRead));
    }
  }
}

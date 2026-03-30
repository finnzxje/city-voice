import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio;

  NotificationService({required Dio dio}) : _dio = dio;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);

    final data = response.data;
    if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<NotificationModel>>.fromJson(
        data,
        fromJsonT: (json) => (json as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data ?? [];
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.unreadCount);

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<int>.fromJson(
        data,
        fromJsonT: (json) {
          if (json is int) return json;
          if (json is num) return json.toInt();
          if (json is String) return int.tryParse(json) ?? 0;
          if (json is Map<String, dynamic>) {
            final count = json['count'];
            if (count is int) return count;
            if (count is num) return count.toInt();
            if (count is String) return int.tryParse(count) ?? 0;
          }
          return 0;
        },
      );
      return apiResponse.data ?? 0;
    }
    return 0;
  }

  Future<void> markAsRead(String id) async {
    await _dio.put(ApiConstants.markNotificationRead(id));
  }
}

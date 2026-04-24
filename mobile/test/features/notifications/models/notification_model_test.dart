import 'package:city_voice/features/notifications/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('normalizes UTC notification timestamps to local time', () {
      final notification = NotificationModel.fromJson(<String, dynamic>{
        'id': 'notif-1',
        'type': 'report_status',
        'message': 'Báo cáo đã được tiếp nhận',
        'isRead': false,
        'createdAt': '2026-04-24T13:49:00Z',
      });

      expect(notification.createdAt.isUtc, isFalse);
      expect(notification.createdAt.hour, 20);
      expect(notification.createdAt.minute, 49);
    });
  });
}

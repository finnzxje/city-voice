import 'package:city_voice/features/reports/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report.fromJson', () {
    test('converts UTC timestamps to local time for display', () {
      final report = Report.fromJson(<String, dynamic>{
        'id': 'report-1',
        'title': 'Ổ gà trước nhà',
        'categoryId': 1,
        'categoryName': 'Ổ gà',
        'latitude': 10.77689,
        'longitude': 106.70081,
        'currentStatus': 'newly_received',
        'createdAt': '2026-04-24T13:49:00Z',
      });

      expect(report.createdAt.isUtc, isFalse);
      expect(report.createdAt.hour, 20);
      expect(report.createdAt.minute, 49);
    });

    test('keeps local timestamps unchanged when backend sends no timezone', () {
      final report = Report.fromJson(<String, dynamic>{
        'id': 'report-2',
        'title': 'Đèn hỏng',
        'categoryId': 2,
        'categoryName': 'Chiếu sáng',
        'latitude': 10.77689,
        'longitude': 106.70081,
        'currentStatus': 'newly_received',
        'createdAt': '2026-04-24T20:49:00',
      });

      expect(report.createdAt.isUtc, isFalse);
      expect(report.createdAt.hour, 20);
      expect(report.createdAt.minute, 49);
    });
  });
}

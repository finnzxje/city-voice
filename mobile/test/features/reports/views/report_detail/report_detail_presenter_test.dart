import 'package:city_voice/features/reports/models/report.dart';
import 'package:city_voice/features/reports/views/report_detail/report_detail_presenter.dart';
import 'package:city_voice/features/reports/views/widgets/timeline_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportDetailPresenter', () {
    test('provides fallback description and status text for new reports', () {
      final presenter = ReportDetailPresenter(
        _buildReport(currentStatus: 'newly_received'),
      );

      expect(
          presenter.descriptionText, 'Không có mô tả chi tiết cho sự cố này.');
      expect(presenter.locationStatusText, 'CHỜ PHÂN CÔNG');
      expect(presenter.bottomStatusText, 'Đang chờ phân công');
      expect(presenter.categoryName, 'Ổ gà');
    });

    test('builds timeline items for rejected reports', () {
      final presenter = ReportDetailPresenter(
        _buildReport(
          currentStatus: 'rejected',
          assignedToName: 'Đội xử lý Quận 1',
          updatedAt: DateTime(2026, 4, 20, 8, 30),
          resolvedAt: DateTime(2026, 4, 20, 10, 15),
        ),
      );

      final items = presenter.timelineItems;

      expect(items, hasLength(3));
      expect(items[1].title, 'Đang xử lý - Đã giao cho Đội xử lý Quận 1');
      expect(items[1].nodeStyle, TimelineNodeStyle.doneGreen);
      expect(items[2].title, 'Từ chối');
      expect(items[2].nodeStyle, TimelineNodeStyle.rejected);
      expect(items[2].isCurrent, isTrue);
      expect(items[2].isResolvedNode, isFalse);
    });
  });
}

Report _buildReport({
  required String currentStatus,
  String? description,
  String? assignedToName,
  DateTime? updatedAt,
  DateTime? resolvedAt,
}) {
  return Report(
    id: 'report-1',
    title: 'Ổ gà trước nhà',
    description: description,
    categoryId: 1,
    categoryName: 'Ổ gà',
    latitude: 10.77689,
    longitude: 106.70081,
    administrativeZoneName: 'Quận 1',
    incidentImageUrl: null,
    resolutionImageUrl: null,
    currentStatus: currentStatus,
    priority: null,
    citizenId: 'citizen-1',
    citizenName: 'Nguyen Van A',
    assignedToId: 'staff-1',
    assignedToName: assignedToName,
    createdAt: DateTime(2026, 4, 19, 7, 0),
    updatedAt: updatedAt,
    resolvedAt: resolvedAt,
  );
}

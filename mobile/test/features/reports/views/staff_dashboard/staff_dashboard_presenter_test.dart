import 'package:city_voice/features/reports/models/report.dart';
import 'package:city_voice/features/reports/views/staff_dashboard/staff_dashboard_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffDashboardPresenter', () {
    test('filters reports by search query and selected date', () {
      final presenter = StaffDashboardPresenter(
        reports: [
          _buildReport(
            id: '1',
            title: 'Ổ gà trước nhà',
            citizenName: 'Nguyen Van A',
            createdAt: DateTime(2026, 4, 21, 8),
          ),
          _buildReport(
            id: '2',
            title: 'Đèn đường hỏng',
            citizenName: 'Tran Thi B',
            createdAt: DateTime(2026, 4, 20, 9),
          ),
        ],
        localFilters: StaffDashboardLocalFilters(
          searchQuery: 'nguyen',
          selectedDate: DateTime(2026, 4, 21),
        ),
        hasRemoteFilters: false,
        now: DateTime(2026, 4, 21, 12),
      );

      expect(presenter.filteredReports.map((report) => report.id), ['1']);
      expect(presenter.isAnyFilterActive, isTrue);
    });

    test('groups reports by date and sorts sections descending', () {
      final presenter = StaffDashboardPresenter(
        reports: [
          _buildReport(
            id: '1',
            title: 'A',
            createdAt: DateTime(2026, 4, 20, 8),
          ),
          _buildReport(
            id: '2',
            title: 'B',
            createdAt: DateTime(2026, 4, 21, 9),
          ),
          _buildReport(
            id: '3',
            title: 'C',
            createdAt: DateTime(2026, 4, 21, 10),
          ),
        ],
        localFilters: const StaffDashboardLocalFilters(),
        hasRemoteFilters: false,
        now: DateTime(2026, 4, 21, 12),
      );

      expect(presenter.dateGroups, hasLength(2));
      expect(presenter.dateGroups[0].header.label, 'HÔM NAY, 21/04');
      expect(
        presenter.dateGroups[0].reports.map((report) => report.id),
        ['2', '3'],
      );
      expect(presenter.dateGroups[1].header.label, 'HÔM QUA, 20/04');
    });

    test('marks filter state active when remote filters exist', () {
      final presenter = StaffDashboardPresenter(
        reports: const [],
        localFilters: const StaffDashboardLocalFilters(),
        hasRemoteFilters: true,
      );

      expect(presenter.isAnyFilterActive, isTrue);
    });
  });
}

Report _buildReport({
  required String id,
  required String title,
  String? citizenName,
  required DateTime createdAt,
}) {
  return Report(
    id: id,
    title: title,
    description: null,
    categoryId: 1,
    categoryName: 'Ổ gà',
    latitude: 10.77689,
    longitude: 106.70081,
    administrativeZoneName: 'Quận 1',
    incidentImageUrl: null,
    resolutionImageUrl: null,
    currentStatus: 'newly_received',
    priority: null,
    citizenId: 'citizen-$id',
    citizenName: citizenName,
    assignedToId: null,
    assignedToName: null,
    createdAt: createdAt,
    updatedAt: null,
    resolvedAt: null,
  );
}

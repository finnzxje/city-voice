import 'dart:io';

import 'package:city_voice/features/reports/models/incident_category.dart';
import 'package:city_voice/features/reports/views/submit_report/submit_report_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubmitReportDraft', () {
    test('validates missing draft pieces in submission order', () {
      expect(
        const SubmitReportDraft().submissionValidationMessage,
        'Vui lòng chọn ảnh sự cố.',
      );

      final withImage = SubmitReportDraft(imageFile: File('evidence.jpg'));
      expect(
        withImage.submissionValidationMessage,
        'Chưa xác định được vị trí. Vui lòng thử lại.',
      );

      final withLocation = withImage.copyWith(
        location: const SubmitReportLocationState(
          latitude: 10.77689,
          longitude: 106.70081,
        ),
      );
      expect(
        withLocation.submissionValidationMessage,
        'Vui lòng chọn danh mục sự cố.',
      );
    });

    test('accepts a complete draft', () {
      final completeDraft = SubmitReportDraft(
        imageFile: File('evidence.jpg'),
        selectedCategory: const IncidentCategory(
          id: 1,
          name: 'Ổ gà',
          slug: 'o-ga',
        ),
        location: const SubmitReportLocationState(
          latitude: 10.77689,
          longitude: 106.70081,
        ),
      );

      expect(completeDraft.submissionValidationMessage, isNull);
    });
  });

  group('SubmitReportLocationState', () {
    test('formats title and subtitle from the current state', () {
      const locatingState = SubmitReportLocationState(isLocating: true);
      expect(locatingState.displayTitle, 'Đang tìm vị trí...');
      expect(locatingState.displaySubtitle, 'Chưa xác định được tọa độ');

      const errorState = SubmitReportLocationState(
        errorMessage: 'Không thể lấy vị trí. Vui lòng thử lại.',
      );
      expect(errorState.displayTitle, 'Lỗi vị trí');
      expect(
        errorState.displaySubtitle,
        'Không thể lấy vị trí. Vui lòng thử lại.',
      );

      const coordinatesState = SubmitReportLocationState(
        latitude: 10.762622,
        longitude: 106.660172,
      );
      expect(
        coordinatesState.displaySubtitle,
        '10.76262, 106.66017',
      );
      expect(
        coordinatesState.initialMapLocation.latitude,
        10.762622,
      );
      expect(
        coordinatesState.initialMapLocation.longitude,
        106.660172,
      );
    });
  });
}

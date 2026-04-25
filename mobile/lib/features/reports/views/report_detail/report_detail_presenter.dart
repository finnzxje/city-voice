import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../widgets/timeline_step.dart';

const _reportDetailLocationPendingColor = Color(0xFF2563EB);
const _reportDetailLocationResolvedColor = Color(0xFF16A34A);
const _reportDetailLocationRejectedColor = Color(0xFFDC2626);

final class ReportDetailPresenter {
  const ReportDetailPresenter(this.report);

  final Report report;

  String get categoryName => report.categoryName;

  String get createdDateText =>
      DateFormat('dd/MM/yyyy').format(report.createdAt);

  String get descriptionText {
    final description = report.description;
    if (description != null && description.isNotEmpty) {
      return description;
    }

    return 'Không có mô tả chi tiết cho sự cố này.';
  }

  String get locationStatusText {
    return switch (report.currentStatus) {
      'newly_received' => 'CHỜ PHÂN CÔNG',
      'in_progress' => 'CHỜ XỬ LÝ',
      'resolved' => 'ĐÃ XỬ LÝ',
      'rejected' => 'BỊ TỪ CHỐI',
      _ => 'KHÔNG RÕ TRẠNG THÁI',
    };
  }

  Color get locationStatusColor {
    return switch (report.currentStatus) {
      'resolved' => _reportDetailLocationResolvedColor,
      'rejected' => _reportDetailLocationRejectedColor,
      _ => _reportDetailLocationPendingColor,
    };
  }

  String get administrativeZoneName =>
      report.administrativeZoneName ?? 'Hồ Chí Minh';

  String get coordinatesText {
    return '${report.latitude.toStringAsFixed(5)}, '
        '${report.longitude.toStringAsFixed(5)}';
  }

  String get bottomStatusText {
    return switch (report.currentStatus) {
      'newly_received' => 'Đang chờ phân công',
      'in_progress' => 'Đang chờ xử lý',
      'resolved' => 'Sự cố đã được khắc phục',
      'rejected' => 'Sự cố đã bị từ chối',
      _ => 'Đang chờ cập nhật',
    };
  }

  List<ReportDetailTimelineItem> get timelineItems {
    final stepStyles = _buildTimelineStepStyles(report.currentStatus);
    final step1Title = _assignedStepTitle(report.assignedToName);
    final step1Date =
        _inProgressStepDate(report.currentStatus, report.updatedAt);

    final items = <ReportDetailTimelineItem>[
      ReportDetailTimelineItem(
        title: 'Mới tiếp nhận',
        date: report.createdAt,
        fallbackSubtitle: null,
        nodeStyle: stepStyles.$1.nodeStyle,
        lineColor: stepStyles.$1.lineColor,
        isLast: false,
        isResolvedNode: false,
        isCurrent: stepStyles.$1.isCurrent,
      ),
      ReportDetailTimelineItem(
        title: step1Title,
        date: step1Date,
        fallbackSubtitle: report.currentStatus == 'newly_received'
            ? 'Đang chờ phân công'
            : null,
        nodeStyle: stepStyles.$2.nodeStyle,
        lineColor: stepStyles.$2.lineColor,
        isLast: false,
        isResolvedNode: false,
        isCurrent: stepStyles.$2.isCurrent,
      ),
    ];

    final isRejected = report.currentStatus == 'rejected';
    items.add(
      ReportDetailTimelineItem(
        title: isRejected ? 'Từ chối' : 'Đã xử lý',
        date: report.resolvedAt,
        fallbackSubtitle: !isRejected && report.currentStatus != 'resolved'
            ? 'Đang chờ xử lý'
            : null,
        nodeStyle: stepStyles.$3.nodeStyle,
        lineColor: kTimelineGreyLine,
        isLast: true,
        isResolvedNode: !isRejected,
        isCurrent: stepStyles.$3.isCurrent,
      ),
    );

    return items;
  }

  String _assignedStepTitle(String? assignedToName) {
    if (assignedToName != null && assignedToName.isNotEmpty) {
      return 'Đang xử lý - Đã giao cho $assignedToName';
    }

    return 'Đang xử lý';
  }

  DateTime? _inProgressStepDate(String status, DateTime? updatedAt) {
    return switch (status) {
      'in_progress' || 'resolved' || 'rejected' => updatedAt,
      _ => null,
    };
  }

  (_TimelineStepVisualState, _TimelineStepVisualState, _TimelineStepVisualState)
      _buildTimelineStepStyles(String status) {
    final step0 = switch (status) {
      'in_progress' ||
      'resolved' ||
      'rejected' =>
        const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.doneGreen,
          isCurrent: false,
        ),
      _ => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.currentBlue,
          isCurrent: true,
        ),
    };

    final step1 = switch (status) {
      'newly_received' => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.pendingGrey,
          isCurrent: false,
        ),
      'in_progress' => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.currentOrange,
          isCurrent: true,
        ),
      'resolved' || 'rejected' => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.doneGreen,
          isCurrent: false,
        ),
      _ => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.pendingGrey,
          isCurrent: false,
        ),
    };

    final step2 = switch (status) {
      'resolved' => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.doneGreen,
          isCurrent: true,
        ),
      'rejected' => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.rejected,
          isCurrent: true,
        ),
      _ => const _TimelineStepVisualState(
          nodeStyle: TimelineNodeStyle.pendingGrey,
          isCurrent: false,
        ),
    };

    return (
      step0.copyWith(lineColor: _lineColorForNextStep(step1.nodeStyle)),
      step1.copyWith(lineColor: _lineColorForNextStep(step2.nodeStyle)),
      step2,
    );
  }

  Color _lineColorForNextStep(TimelineNodeStyle nextStepStyle) {
    return _isActive(nextStepStyle) ? kTimelineGreenLine : kTimelineGreyLine;
  }

  bool _isActive(TimelineNodeStyle style) {
    return style == TimelineNodeStyle.doneGreen ||
        style == TimelineNodeStyle.currentBlue ||
        style == TimelineNodeStyle.currentOrange ||
        style == TimelineNodeStyle.rejected;
  }
}

final class ReportDetailTimelineItem {
  const ReportDetailTimelineItem({
    required this.title,
    required this.date,
    required this.fallbackSubtitle,
    required this.nodeStyle,
    required this.lineColor,
    required this.isLast,
    required this.isResolvedNode,
    required this.isCurrent,
  });

  final String title;
  final DateTime? date;
  final String? fallbackSubtitle;
  final TimelineNodeStyle nodeStyle;
  final Color lineColor;
  final bool isLast;
  final bool isResolvedNode;
  final bool isCurrent;
}

final class _TimelineStepVisualState {
  const _TimelineStepVisualState({
    required this.nodeStyle,
    required this.isCurrent,
    this.lineColor = kTimelineGreyLine,
  });

  final TimelineNodeStyle nodeStyle;
  final bool isCurrent;
  final Color lineColor;

  _TimelineStepVisualState copyWith({
    TimelineNodeStyle? nodeStyle,
    bool? isCurrent,
    Color? lineColor,
  }) {
    return _TimelineStepVisualState(
      nodeStyle: nodeStyle ?? this.nodeStyle,
      isCurrent: isCurrent ?? this.isCurrent,
      lineColor: lineColor ?? this.lineColor,
    );
  }
}

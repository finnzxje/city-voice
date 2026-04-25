import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';

const Object _selectedDateUnset = Object();

final class StaffDashboardLocalFilters {
  const StaffDashboardLocalFilters({
    this.searchQuery = '',
    this.selectedDate,
  });

  final String searchQuery;
  final DateTime? selectedDate;

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty || selectedDate != null;

  StaffDashboardLocalFilters copyWith({
    String? searchQuery,
    Object? selectedDate = _selectedDateUnset,
  }) {
    return StaffDashboardLocalFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: identical(selectedDate, _selectedDateUnset)
          ? this.selectedDate
          : selectedDate as DateTime?,
    );
  }
}

final class StaffDashboardPresenter {
  StaffDashboardPresenter({
    required List<Report> reports,
    required this.localFilters,
    required this.hasRemoteFilters,
    DateTime? now,
  })  : _reports = reports,
        _now = now ?? DateTime.now();

  final List<Report> _reports;
  final StaffDashboardLocalFilters localFilters;
  final bool hasRemoteFilters;
  final DateTime _now;

  List<Report> get filteredReports {
    return _reports.where(_matchesFilters).toList();
  }

  List<StaffDashboardDateGroup> get dateGroups {
    final groupedReports = <DateTime, List<Report>>{};
    for (final report in filteredReports) {
      final date = DateUtils.dateOnly(report.createdAt);
      groupedReports.putIfAbsent(date, () => <Report>[]).add(report);
    }

    final sortedDates = groupedReports.keys.toList()
      ..sort((left, right) => right.compareTo(left));

    return sortedDates
        .map(
          (date) => StaffDashboardDateGroup(
            date: date,
            reports: groupedReports[date]!,
            header: buildDateHeader(date),
          ),
        )
        .toList();
  }

  bool get isAnyFilterActive =>
      hasRemoteFilters || localFilters.hasActiveFilters;

  StaffDashboardDateHeader buildDateHeader(DateTime date) {
    final today = DateUtils.dateOnly(_now);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return StaffDashboardDateHeader(
        label: 'HÔM NAY, ${DateFormat('dd/MM').format(date)}',
        isToday: true,
      );
    }

    if (date == yesterday) {
      return StaffDashboardDateHeader(
        label: 'HÔM QUA, ${DateFormat('dd/MM').format(date)}',
        isToday: false,
      );
    }

    return StaffDashboardDateHeader(
      label: DateFormat('dd/MM/yyyy').format(date),
      isToday: false,
    );
  }

  bool _matchesFilters(Report report) {
    final query = localFilters.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matchesTitle = report.title.toLowerCase().contains(query);
      final citizenName = report.citizenName?.toLowerCase();
      final matchesCitizen = citizenName?.contains(query) ?? false;
      if (!matchesTitle && !matchesCitizen) {
        return false;
      }
    }

    final selectedDate = localFilters.selectedDate;
    if (selectedDate != null &&
        !DateUtils.isSameDay(report.createdAt, selectedDate)) {
      return false;
    }

    return true;
  }
}

final class StaffDashboardDateGroup {
  const StaffDashboardDateGroup({
    required this.date,
    required this.reports,
    required this.header,
  });

  final DateTime date;
  final List<Report> reports;
  final StaffDashboardDateHeader header;
}

final class StaffDashboardDateHeader {
  const StaffDashboardDateHeader({
    required this.label,
    required this.isToday,
  });

  final String label;
  final bool isToday;
}

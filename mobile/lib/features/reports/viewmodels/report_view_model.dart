import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_error_message_resolver.dart';
import '../models/incident_category.dart';
import '../models/report.dart';
import '../services/category_service.dart';
import '../services/report_service.dart';

/// Manages reports and categories state for citizen screens.

class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final CategoryService _categoryService;

  ReportViewModel({
    required ReportService reportService,
    required CategoryService categoryService,
  })  : _reportService = reportService,
        _categoryService = categoryService;

  // ── Observable state ───────────────────────────────────────────────────────
  List<Report> _reports = [];
  List<Report> get reports => _reports;

  List<IncidentCategory> _categories = [];
  List<IncidentCategory> get categories => _categories;

  Report? _selectedReport;
  Report? get selectedReport => _selectedReport;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  ReportDashboardSnapshot? _dashboardSnapshotCache;
  List<Report>? _dashboardSnapshotReportsSource;
  String? _dashboardSnapshotStatus;
  String? _dashboardSnapshotCategory;

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setLoading(bool v, {bool notify = true}) {
    _isLoading = v;
    if (notify) {
      notifyListeners();
    }
  }

  void _setError(String? msg, {bool notify = true}) {
    _errorMessage = msg;
    _successMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _setSuccess(String? msg, {bool notify = true}) {
    _successMessage = msg;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  ReportDashboardSnapshot dashboardSnapshot({
    String? selectedStatus,
    String? selectedCategory,
  }) {
    final cachedSnapshot = _dashboardSnapshotCache;
    if (cachedSnapshot != null &&
        identical(_dashboardSnapshotReportsSource, _reports) &&
        _dashboardSnapshotStatus == selectedStatus &&
        _dashboardSnapshotCategory == selectedCategory) {
      return cachedSnapshot;
    }

    var newlyReceivedCount = 0;
    var inProgressCount = 0;
    var resolvedCount = 0;
    var rejectedCount = 0;
    final filteredReports = <Report>[];

    for (final report in _reports) {
      switch (report.currentStatus) {
        case 'newly_received':
          newlyReceivedCount += 1;
          break;
        case 'in_progress':
          inProgressCount += 1;
          break;
        case 'resolved':
          resolvedCount += 1;
          break;
        case 'rejected':
          rejectedCount += 1;
          break;
      }

      if (selectedStatus != null && report.currentStatus != selectedStatus) {
        continue;
      }

      if (selectedCategory != null && report.categoryName != selectedCategory) {
        continue;
      }

      filteredReports.add(report);
    }

    final items = <ReportDashboardItem>[];
    DateTime? previousDate;

    for (var index = 0; index < filteredReports.length; index += 1) {
      final report = filteredReports[index];
      final currentDate = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      final showDate = previousDate == null || currentDate != previousDate;

      items.add(
        ReportDashboardItem(
          report: report,
          showDate: showDate,
          isLast: index == filteredReports.length - 1,
        ),
      );

      previousDate = currentDate;
    }

    final snapshot = ReportDashboardSnapshot(
      items: items,
      newlyReceivedCount: newlyReceivedCount,
      inProgressCount: inProgressCount,
      resolvedCount: resolvedCount,
      rejectedCount: rejectedCount,
    );

    _dashboardSnapshotCache = snapshot;
    _dashboardSnapshotReportsSource = _reports;
    _dashboardSnapshotStatus = selectedStatus;
    _dashboardSnapshotCategory = selectedCategory;

    return snapshot;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load dashboard reports for the initial citizen first paint.
  Future<void> loadDashboard() async {
    _setLoading(true, notify: false);
    _setError(null, notify: false);
    notifyListeners();
    try {
      _reports = List<Report>.of(await _reportService.getMyReports());
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e), notify: false);
    } finally {
      _setLoading(false, notify: false);
      notifyListeners();
    }
  }

  /// Load staff/admin dashboard: all reports (not just own) + categories.
  Future<void> loadStaffDashboard() async {
    _setLoading(true, notify: false);
    _setError(null, notify: false);
    notifyListeners();
    try {
      final results = await Future.wait([
        _reportService.getAllReports(),
        _categoryService.getCategories(),
      ]);
      _reports = List<Report>.of(results[0] as List<Report>);
      _categories = List<IncidentCategory>.of(
        results[1] as List<IncidentCategory>,
      );
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e), notify: false);
    } finally {
      _setLoading(false, notify: false);
      notifyListeners();
    }
  }

  /// Refresh only the report list (pull-to-refresh).
  Future<void> refreshReports() async {
    try {
      _reports = List<Report>.of(await _reportService.getMyReports());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    }
  }

  /// Refresh for staff (all reports).
  Future<void> refreshStaffReports() async {
    try {
      _reports = List<Report>.of(await _reportService.getAllReports());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    }
  }

  /// Fetch categories (for the submit report form).
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      _categories = List<IncidentCategory>.of(
        await _categoryService.getCategories(),
      );
      notifyListeners();
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    }
  }

  /// Submit a new report.
  Future<String?> submitReport({
    required String title,
    String? description,
    required int categoryId,
    required double latitude,
    required double longitude,
    required File imageFile,
  }) async {
    _isSubmitting = true;
    _setError(null, notify: false);
    notifyListeners();
    try {
      final report = await _reportService.submitReport(
        title: title,
        description: description,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
        imageFile: imageFile,
      );
      _reports = [report, ..._reports];
      _setSuccess('Báo cáo đã được gửi thành công!', notify: false);
      return report.id;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e), notify: false);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Load a single report for the detail screen.
  Future<void> loadReportDetail(String id) async {
    _setLoading(true, notify: false);
    _setError(null, notify: false);
    _selectedReport = null;
    notifyListeners();
    try {
      _selectedReport = await _reportService.getReportById(id);
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e), notify: false);
    } finally {
      _setLoading(false, notify: false);
      notifyListeners();
    }
  }
}

final class ReportDashboardSnapshot {
  const ReportDashboardSnapshot({
    required this.items,
    required this.newlyReceivedCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.rejectedCount,
  });

  final List<ReportDashboardItem> items;
  final int newlyReceivedCount;
  final int inProgressCount;
  final int resolvedCount;
  final int rejectedCount;

  int get displayedCount => items.length;

  bool get isEmpty => items.isEmpty;
}

final class ReportDashboardItem {
  const ReportDashboardItem({
    required this.report,
    required this.showDate,
    required this.isLast,
  });

  final Report report;
  final bool showDate;
  final bool isLast;
}

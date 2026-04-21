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

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? msg) {
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load all dashboard data: reports and categories.
  Future<void> loadDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _reportService.getMyReports(),
        _categoryService.getCategories(),
      ]);
      _reports = results[0] as List<Report>;
      _categories = results[1] as List<IncidentCategory>;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Load staff/admin dashboard: all reports (not just own) + categories.
  Future<void> loadStaffDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _reportService.getAllReports(),
        _categoryService.getCategories(),
      ]);
      _reports = results[0] as List<Report>;
      _categories = results[1] as List<IncidentCategory>;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh only the report list (pull-to-refresh).
  Future<void> refreshReports() async {
    try {
      _reports = await _reportService.getMyReports();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    }
  }

  /// Refresh for staff (all reports).
  Future<void> refreshStaffReports() async {
    try {
      _reports = await _reportService.getAllReports();
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
      _categories = await _categoryService.getCategories();
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
    _setError(null);
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
      // Add new report to the top of the list.
      _reports.insert(0, report);
      _setSuccess('Báo cáo đã được gửi thành công!');
      _isSubmitting = false;
      notifyListeners();
      return report.id;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Load a single report for the detail screen.
  Future<void> loadReportDetail(String id) async {
    _setLoading(true);
    _setError(null);
    _selectedReport = null;
    try {
      _selectedReport = await _reportService.getReportById(id);
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    } finally {
      _setLoading(false);
    }
  }
}

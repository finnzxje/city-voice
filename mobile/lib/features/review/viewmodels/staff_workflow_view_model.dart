import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../reports/models/incident_category.dart';
import '../../reports/models/report.dart';
import '../../reports/services/category_service.dart';
import '../models/review_request.dart';
import '../models/reject_request.dart';
import '../services/staff_report_service.dart';

class StaffWorkflowViewModel extends ChangeNotifier {
  final StaffReportService _service;
  final CategoryService _categoryService;

  StaffWorkflowViewModel({
    required StaffReportService service,
    required CategoryService categoryService,
  })  : _service = service,
        _categoryService = categoryService;

  // ── Observable state ───────────────────────────────────────────────────────

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _actionError;
  String? get actionError => _actionError;

  Report? _selectedReport;
  Report? get selectedReport => _selectedReport;

  // ── Filters ───────────────────────────────────────────────────────────────

  String? _statusFilter;

  String? get statusFilter => _statusFilter;

  String? _priorityFilter;

  String? get priorityFilter => _priorityFilter;

  int? _categoryIdFilter;

  int? get categoryIdFilter => _categoryIdFilter;

  // ── Categories ────────────────────────────────────────────────────────────

  List<IncidentCategory> _categories = [];

  List<IncidentCategory> get categories => _categories;

  bool _categoriesLoaded = false;

  /// Load categories (once).
  Future<void> loadCategories() async {
    if (_categoriesLoaded) return;
    try {
      _categories = await _categoryService.getCategories();
      _categoriesLoaded = true;
      notifyListeners();
    } catch (_) {
      // Non-critical — categories dropdown will just be empty.
    }
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  int _currentPage = 0;

  int get currentPage => _currentPage;

  int _totalPages = 1;

  int get totalPages => _totalPages;

  static const int pageSize = 15;

  // ── List / Filter ─────────────────────────────────────────────────────────

  /// Loads reports with the current filters + page applied via API query params.
  Future<void> loadReports({int page = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getReports(
        status: _statusFilter,
        priority: _priorityFilter,
        categoryId: _categoryIdFilter,
        page: page,
        size: pageSize,
      );
      _reports = result.reports;
      _currentPage = result.currentPage;
      _totalPages = result.totalPages;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the status filter and reloads from page 0.
  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadReports();
  }

  /// Sets the priority filter and reloads from page 0.
  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    loadReports();
  }

  /// Sets the category filter and reloads from page 0.
  void setCategoryFilter(int? categoryId) {
    _categoryIdFilter = categoryId;
    loadReports();
  }

  /// Clears all filters and reloads.
  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _categoryIdFilter = null;
    loadReports();
  }

  /// Whether any filter is active.
  bool get hasActiveFilters =>
      _statusFilter != null ||
      _priorityFilter != null ||
      _categoryIdFilter != null;

  /// Navigate to a specific page.
  void goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      loadReports(page: page);
    }
  }

  /// Loads a single report detail.
  Future<void> loadReportDetail(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedReport = null;
    notifyListeners();

    try {
      // Find in cached list first
      final cached = _reports.where((r) => r.id == reportId).toList();
      if (cached.isNotEmpty) {
        _selectedReport = cached.first;
      } else {
        // Fallback: fetch all and find
        final result = await _service.getReports(size: 100);
        _selectedReport =
            result.reports.where((r) => r.id == reportId).firstOrNull;
      }
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Review: newly_received → in_progress
  Future<bool> reviewReport({
    required String reportId,
    required String priority,
    required String assignedTo,
    String? note,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await _service.reviewReport(
        reportId,
        ReviewRequest(
          priority: priority,
          assignedTo: assignedTo,
          note: note,
        ),
      );
      _replaceReport(updated);
      _selectedReport = updated;
      return true;
    } on DioException catch (e) {
      _actionError = _extractError(e);
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Reject: newly_received → rejected
  Future<bool> rejectReport({
    required String reportId,
    required String note,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await _service.rejectReport(
        reportId,
        RejectRequest(note: note),
      );
      _replaceReport(updated);
      _selectedReport = updated;
      return true;
    } on DioException catch (e) {
      _actionError = _extractError(e);
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Resolve: in_progress → resolved (multipart with proof image)
  Future<bool> resolveReport({
    required String reportId,
    required File imageFile,
    String? note,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await _service.resolveReport(
        reportId,
        imageFile,
        note: note,
      );
      _replaceReport(updated);
      _selectedReport = updated;
      return true;
    } on DioException catch (e) {
      _actionError = _extractError(e);
      return false;
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _replaceReport(Report updated) {
    final index = _reports.indexWhere((r) => r.id == updated.id);
    if (index >= 0) {
      _reports = List<Report>.from(_reports)..[index] = updated;
    }
    notifyListeners();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 'Đã xảy ra lỗi';
    }
    return e.message ?? 'Đã xảy ra lỗi kết nối';
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/incident_category.dart';
import '../models/notification_model.dart';
import '../models/report.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';

/// Manages reports, categories, and notifications state for citizen screens.
class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final CategoryService _categoryService;
  final NotificationService _notificationService;

  ReportViewModel({
    required ReportService reportService,
    required CategoryService categoryService,
    required NotificationService notificationService,
  })  : _reportService = reportService,
        _categoryService = categoryService,
        _notificationService = notificationService;

  // ── Observable state ───────────────────────────────────────────────────────
  List<Report> _reports = [];

  List<Report> get reports => _reports;

  List<IncidentCategory> _categories = [];

  List<IncidentCategory> get categories => _categories;

  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

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

  String _extractError(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    if (e is ApiException) return e.message;
    return 'Đã xảy ra lỗi không xác định.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load all dashboard data: reports, categories, notification count.
  Future<void> loadDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _reportService.getMyReports(),
        _categoryService.getCategories(),
        // _notificationService.getUnreadCount(),
      ]);
      _reports = results[0] as List<Report>;
      _categories = results[1] as List<IncidentCategory>;
      // _unreadCount = results[2] as int;
    } catch (e) {
      _setError(_extractError(e));
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
      _setError(_extractError(e));
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
      _setError(_extractError(e));
    }
  }

  /// Refresh for staff (all reports).
  Future<void> refreshStaffReports() async {
    try {
      _reports = await _reportService.getAllReports();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError(_extractError(e));
    }
  }

  /// Fetch categories (for the submit report form).
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      _categories = await _categoryService.getCategories();
      notifyListeners();
    } catch (e) {
      _setError(_extractError(e));
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
      _setError(_extractError(e));
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
      _setError(_extractError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  /// Fetch all notifications (for notification list/panel).
  // Future<void> loadNotifications() async {
  //   try {
  //     _notifications = await _notificationService.getNotifications();
  //     _unreadCount = _notifications.where((n) => !n.isRead).length;
  //     notifyListeners();
  //   } catch (_) {}
  // }

  /// Mark a notification as read.
  Future<void> markNotificationRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        // Create a new instance since the model is immutable
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Refresh the unread badge count.
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }
}

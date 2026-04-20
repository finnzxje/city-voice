import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/analytics_filter.dart';
import '../models/heatmap_point.dart';
import '../models/stats_model.dart';
import '../services/analytics_service.dart';

/// View states for async operations.
enum AnalyticsViewState { idle, loading, success, error }

/// ViewModel for the analytics dashboard (manager + admin).
class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsService _service;

  AnalyticsViewModel({required AnalyticsService service}) : _service = service;

  // ── Filter state ───────────────────────────────────────────────────────────
  AnalyticsFilter _activeFilter = AnalyticsFilter();

  AnalyticsFilter get activeFilter => _activeFilter;

  // ── Stats state ────────────────────────────────────────────────────────────
  StatsModel? _stats;

  StatsModel? get stats => _stats;

  AnalyticsViewState _statsState = AnalyticsViewState.idle;

  AnalyticsViewState get statsState => _statsState;

  String? _statsError;

  String? get statsError => _statsError;

  // ── Heatmap state ──────────────────────────────────────────────────────────
  List<HeatmapPoint> _heatmapPoints = [];

  List<HeatmapPoint> get heatmapPoints => _heatmapPoints;

  AnalyticsViewState _heatmapState = AnalyticsViewState.idle;

  AnalyticsViewState get heatmapState => _heatmapState;

  String? _heatmapError;

  String? get heatmapError => _heatmapError;

  // ── Export state ───────────────────────────────────────────────────────────
  AnalyticsViewState _exportState = AnalyticsViewState.idle;

  AnalyticsViewState get exportState => _exportState;

  String? _exportError;

  String? get exportError => _exportError;

  String? _lastExportedPath;

  String? get lastExportedPath => _lastExportedPath;

  String? _exportType;

  String? get exportType => _exportType;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Loads stats and heatmap concurrently using current [activeFilter].
  Future<void> loadDashboard() async {
    _statsState = AnalyticsViewState.loading;
    _heatmapState = AnalyticsViewState.loading;
    _statsError = null;
    _heatmapError = null;
    notifyListeners();

    // Run both fetches concurrently; handle failures independently.
    await Future.wait([
      _loadStats(),
      _loadHeatmap(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _service.getStats(_activeFilter);
      _statsState = AnalyticsViewState.success;
    } on DioException catch (e) {
      _statsError = _extractDioError(e);
      _statsState = AnalyticsViewState.error;
    } catch (e) {
      _statsError = e.toString();
      _statsState = AnalyticsViewState.error;
    }
    notifyListeners();
  }

  Future<void> _loadHeatmap() async {
    try {
      _heatmapPoints = await _service.getHeatmap(_activeFilter);
      _heatmapState = AnalyticsViewState.success;
    } on DioException catch (e) {
      _heatmapError = _extractDioError(e);
      _heatmapState = AnalyticsViewState.error;
    } catch (e) {
      _heatmapError = e.toString();
      _heatmapState = AnalyticsViewState.error;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Replaces the active filter and reloads the dashboard.
  Future<void> applyFilter(AnalyticsFilter newFilter) async {
    _activeFilter = newFilter;
    notifyListeners();
    await loadDashboard();
  }

  /// Resets filters to defaults and reloads.
  Future<void> resetFilter() async {
    _activeFilter = AnalyticsFilter();
    notifyListeners();
    await loadDashboard();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> exportExcel() => _export('excel');

  Future<void> exportPdf() => _export('pdf');

  Future<void> _export(String type) async {
    _exportState = AnalyticsViewState.loading;
    _exportError = null;
    _lastExportedPath = null;
    _exportType = type;
    notifyListeners();

    try {
      final bytes = await _service.exportFile(type, _activeFilter);
      if (bytes.isEmpty) {
        _exportError = 'File trống, vui lòng thử lại';
        _exportState = AnalyticsViewState.error;
        notifyListeners();
        return;
      }
      // Try to get Downloads directory, fallback to Documents
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final ext = type == 'excel' ? 'xlsx' : 'pdf';
      final filename =
          'cityvoice-reports-${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      _lastExportedPath = file.path;
      _exportState = AnalyticsViewState.success;

      debugPrint('Exported to: ${file.path}');

      // Try to open; don't fail the export if open fails.
      try {
        await OpenFilex.open(file.path);
      } catch (_) {
        // No app to open, but file is saved — that's still success.
      }
    } on DioException catch (e) {
      _exportError = _extractDioError(e);
      _exportState = AnalyticsViewState.error;
    } catch (e) {
      _exportError = 'Không thể xuất file: $e';
      _exportState = AnalyticsViewState.error;
    }
    notifyListeners();
  }

  /// Resets export state so the UI doesn't show the same notification multiple times.
  void clearExportState() {
    _exportState = AnalyticsViewState.idle;
    _lastExportedPath = null;
    _exportType = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _extractDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 'Đã xảy ra lỗi';
    }
    return e.message ?? 'Lỗi kết nối';
  }
}

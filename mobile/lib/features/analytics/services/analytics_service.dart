import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/analytics_filter.dart';
import '../models/heatmap_point.dart';
import '../models/stats_model.dart';

/// Service for analytics API calls (manager/admin only).
class AnalyticsService {
  final Dio _dio;

  AnalyticsService({required Dio dio}) : _dio = dio;

  /// Fetches heatmap data points.
  /// GET /analytics/heatmap
  Future<List<HeatmapPoint>> getHeatmap(AnalyticsFilter filter) async {
    final response = await _dio.get(
      ApiConstants.analyticsHeatmap,
      queryParameters: filter.toQueryParams(),
    );
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<HeatmapPoint>>.fromJson(
        data,
        fromJsonT: (json) => (json as List)
            .map((e) => HeatmapPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data ?? [];
    }

    if (data is List) {
      return data
          .map((e) => HeatmapPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches aggregated statistics.
  /// GET /analytics/stats
  Future<StatsModel> getStats(AnalyticsFilter filter) async {
    final response = await _dio.get(
      ApiConstants.analyticsStats,
      queryParameters: filter.toQueryParams(),
    );
    final data = response.data;

    if (data is Map<String, dynamic>) {
      // Wrapped: { "code": 200, "data": {...} }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StatsModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StatsModel.fromJson(data);
    }
    throw Exception('Unexpected stats response format');
  }

  /// Downloads an export file (Excel or PDF) as raw bytes.
  /// GET /analytics/export/excel  OR  GET /analytics/export/pdf
  Future<Uint8List> exportFile(String type, AnalyticsFilter filter) async {
    final path = type == 'excel'
        ? ApiConstants.analyticsExportExcel
        : ApiConstants.analyticsExportPdf;

    final response = await _dio.get<List<int>>(
      path,
      queryParameters: filter.toQueryParams(),
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data ?? []);
  }
}

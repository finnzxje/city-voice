import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_payload_parser.dart';
import '../models/analytics_filter.dart';
import '../models/heatmap_point.dart';
import '../models/stats_model.dart';

/// Service for analytics API calls (manager/admin only).
class AnalyticsService {
  static const int _heatmapComputeThreshold = 200;

  final Dio _dio;

  AnalyticsService({required Dio dio}) : _dio = dio;

  /// Fetches heatmap data points.
  /// GET /analytics/heatmap
  Future<List<HeatmapPoint>> getHeatmap(AnalyticsFilter filter) async {
    final response = await _dio.get(
      ApiConstants.analyticsHeatmap,
      queryParameters: filter.toQueryParams(),
    );
    final payload = _extractHeatmapPayload(response.data);
    if (payload.isEmpty) {
      return const <HeatmapPoint>[];
    }

    if (payload.length < _heatmapComputeThreshold) {
      return _parseHeatmapPayload(payload);
    }

    return compute(_parseHeatmapPayload, payload);
  }

  /// Fetches aggregated statistics.
  /// GET /analytics/stats
  Future<StatsModel> getStats(AnalyticsFilter filter) async {
    final response = await _dio.get(
      ApiConstants.analyticsStats,
      queryParameters: filter.toQueryParams(),
    );
    return StatsModel.fromJson(
      ApiPayloadParser.requireObject(
        response.data,
        errorMessage: 'Unexpected stats response format',
      ),
    );
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

  List<Map<String, dynamic>> _extractHeatmapPayload(dynamic data) {
    return _copyHeatmapPayload(ApiPayloadParser.listData(data));
  }
}

List<Map<String, dynamic>> _copyHeatmapPayload(List<dynamic> rawItems) {
  return rawItems
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<HeatmapPoint> _parseHeatmapPayload(List<Map<String, dynamic>> payload) {
  return payload.map(HeatmapPoint.fromJson).toList(growable: false);
}

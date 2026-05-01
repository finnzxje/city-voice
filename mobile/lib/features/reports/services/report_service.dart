import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_payload_parser.dart';
import '../models/report.dart';

/// Service for all report-related API calls (citizen-facing).
class ReportService {
  final Dio _dio;

  ReportService({required Dio dio}) : _dio = dio;

  Report _parseReportObject(dynamic data) =>
      Report.fromJson(ApiPayloadParser.requireObject(data));

  List<Report> _parseReportList(dynamic data) {
    return ApiPayloadParser.parseList(
      data,
      fromJson: Report.fromJson,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Submit a new report
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submits a new incident report with an image (multipart/form-data).
  Future<Report> submitReport({
    required String title,
    String? description,
    required int categoryId,
    required double latitude,
    required double longitude,
    required File imageFile,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'categoryId': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      if (description != null && description.isNotEmpty)
        'description': description,
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      ApiConstants.reports,
      data: formData,
    );

    return _parseReportObject(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // My reports (citizen)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all reports submitted by the current citizen.
  Future<List<Report>> getMyReports() async {
    final response = await _dio.get(ApiConstants.myReports);
    return _parseReportList(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Report detail
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches a single report by its UUID.
  Future<Report> getReportById(String id) async {
    final response = await _dio.get(ApiConstants.reportById(id));
    return _parseReportObject(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // All reports (staff / admin)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all reports (paginated). Used by staff/admin dashboards.
  Future<List<Report>> getAllReports({
    int page = 0,
    int size = 50,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null) 'status': status,
    };

    final response = await _dio.get(
      ApiConstants.reports,
      queryParameters: queryParams,
    );

    final paginatedData =
        ApiPayloadParser.paginatedDataMapOrNull(response.data);
    if (paginatedData != null) {
      return ApiPayloadParser.parseList(
        paginatedData['content'],
        fromJson: Report.fromJson,
      );
    }

    return _parseReportList(response.data);
  }
}

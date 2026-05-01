import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_payload_parser.dart';
import '../../reports/models/report.dart';
import '../models/reject_request.dart';
import '../models/review_request.dart';

/// Paginated result wrapper.
class PaginatedResult {
  final List<Report> reports;
  final int totalPages;
  final int currentPage;

  const PaginatedResult({
    required this.reports,
    required this.totalPages,
    required this.currentPage,
  });
}

/// Service for staff / manager / admin report management API calls.
class StaffReportService {
  final Dio _dio;

  StaffReportService({required Dio dio}) : _dio = dio;

  Report _parseReportObject(dynamic data) =>
      Report.fromJson(ApiPayloadParser.requireObject(data));

  // ═══════════════════════════════════════════════════════════════════════════
  // List all reports (paginated, filterable)
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /reports — returns paginated list of all reports.
  Future<PaginatedResult> getReports({
    String? status,
    String? priority,
    int? categoryId,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (categoryId != null) 'categoryId': categoryId,
    };

    final response = await _dio.get(
      ApiConstants.reports,
      queryParameters: queryParams,
    );

    final paginatedData =
        ApiPayloadParser.paginatedDataMapOrNull(response.data);
    if (paginatedData != null) {
      return PaginatedResult(
        reports: ApiPayloadParser.parseList(
          paginatedData['content'],
          fromJson: Report.fromJson,
        ),
        totalPages: _readInt(paginatedData['totalPages'], fallback: 1),
        currentPage: _readInt(paginatedData['number'], fallback: page),
      );
    }

    return PaginatedResult(
      reports: ApiPayloadParser.parseList(
        response.data,
        fromJson: Report.fromJson,
      ),
      totalPages: 1,
      currentPage: page,
    );
  }

  /// GET /reports/{id}
  Future<Report> getReportById(String reportId) async {
    final response = await _dio.get(ApiConstants.reportById(reportId));
    return _parseReportObject(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Review → newly_received → in_progress
  // ═══════════════════════════════════════════════════════════════════════════

  /// PUT /reports/{id}/review
  Future<Report> reviewReport(String reportId, ReviewRequest body) async {
    final response = await _dio.put(
      ApiConstants.reviewReport(reportId),
      data: body.toJson(),
    );
    return _parseReportObject(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reject → newly_received → rejected
  // ═══════════════════════════════════════════════════════════════════════════

  /// PUT /reports/{id}/reject
  Future<Report> rejectReport(String reportId, RejectRequest body) async {
    final response = await _dio.put(
      ApiConstants.rejectReport(reportId),
      data: body.toJson(),
    );
    return _parseReportObject(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Resolve → in_progress → resolved (multipart)
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /reports/{id}/resolve
  Future<Report> resolveReport(
    String reportId,
    File imageFile, {
    String? note,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      if (note != null && note.isNotEmpty) 'note': note,
    });

    Response response;
    try {
      response = await _dio.post(
        ApiConstants.resolveReport(reportId),
        data: formData,
      );
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiException &&
          apiError.code == 403 &&
          apiError.message.contains('được giao')) {
        throw ReportAssignmentException(message: apiError.message);
      }
      rethrow;
    }

    return _parseReportObject(response.data);
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

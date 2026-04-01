import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<PaginatedResult>.fromJson(
        data,
        fromJsonT: (json) {
          if (json is List) {
            return PaginatedResult(
              reports: json
                  .map((e) => Report.fromJson(e as Map<String, dynamic>))
                  .toList(),
              totalPages: 1,
              currentPage: page,
            );
          }
          // Paginated: { "content": [...], "totalPages": ..., ... }
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            return PaginatedResult(
              reports: (json['content'] as List)
                  .map((e) => Report.fromJson(e as Map<String, dynamic>))
                  .toList(),
              totalPages: (json['totalPages'] as int?) ?? 1,
              currentPage: (json['number'] as int?) ?? page,
            );
          }
          return PaginatedResult(
            reports: [],
            totalPages: 1,
            currentPage: page,
          );
        },
      );
      return apiResponse.data ??
          PaginatedResult(reports: [], totalPages: 1, currentPage: page);
    }
    return PaginatedResult(reports: [], totalPages: 1, currentPage: page);
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<Report>.fromJson(
        data,
        fromJsonT: (json) => Report.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    }
    throw Exception('Unexpected response format');
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<Report>.fromJson(
        data,
        fromJsonT: (json) => Report.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    }
    throw Exception('Unexpected response format');
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<Report>.fromJson(
        data,
        fromJsonT: (json) => Report.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!;
    }
    throw Exception('Unexpected response format');
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../reports/models/report.dart';
import '../models/review_request.dart';
import '../models/reject_request.dart';

/// Service for staff / manager / admin report management API calls.
class StaffReportService {
  final Dio _dio;

  StaffReportService({required Dio dio}) : _dio = dio;

  // ═══════════════════════════════════════════════════════════════════════════
  // List all reports (paginated, filterable)
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /reports — returns paginated list of all reports.
  Future<List<Report>> getReports({
    String? status,
    String? priority,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
    };

    final response = await _dio.get(
      ApiConstants.reports,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<Report>>.fromJson(
        data,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map((e) => Report.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // Paginated: { "content": [...], "totalPages": ..., ... }
          if (json is Map<String, dynamic> && json.containsKey('content')) {
            return (json['content'] as List)
                .map((e) => Report.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
      return apiResponse.data ?? [];
    }
    return [];
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

    final response = await _dio.post(
      ApiConstants.resolveReport(reportId),
      data: formData,
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
}

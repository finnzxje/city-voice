import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/report.dart';

/// Service for all report-related API calls (citizen-facing).
class ReportService {
  final Dio _dio;

  ReportService({required Dio dio}) : _dio = dio;

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
  // My reports (citizen)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all reports submitted by the current citizen.
  Future<List<Report>> getMyReports() async {
    final response = await _dio.get(ApiConstants.myReports);

    final data = response.data;
    if (data is List) {
      return data.map((item) {
        // Mỗi item trong List là một Map chứa id, name, slug, iconKey
        return Report.fromJson(item as Map<String, dynamic>);
      }).toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Report detail
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches a single report by its UUID.
  Future<Report> getReportById(String id) async {
    final response = await _dio.get(ApiConstants.reportById(id));

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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Backend returns paginated: { "data": { "content": [...], ... } }
      final apiResponse = ApiResponse<List<Report>>.fromJson(
        data,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map((e) => Report.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // Paginated response: json is { "content": [...], ... }
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
}

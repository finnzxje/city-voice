import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/incident_category.dart';

/// Service for fetching incident categories.
class CategoryService {
  final Dio _dio;

  CategoryService({required Dio dio}) : _dio = dio;

  List<IncidentCategory> _parseCategoryList(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final apiResponse = ApiResponse<List<IncidentCategory>>.fromJson(
        data,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map((item) =>
                    IncidentCategory.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <IncidentCategory>[];
        },
      );
      return apiResponse.data ?? [];
    }

    if (data is List) {
      return data
          .map(
              (item) => IncidentCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Fetches all active categories.
  Future<List<IncidentCategory>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return _parseCategoryList(response.data);
  }
}

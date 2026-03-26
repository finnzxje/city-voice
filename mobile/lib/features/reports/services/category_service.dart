import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/incident_category.dart';

/// Service for fetching incident categories.
class CategoryService {
  final Dio _dio;

  CategoryService({required Dio dio}) : _dio = dio;

  /// Fetches all active categories.
  Future<List<IncidentCategory>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);

    final data = response.data;
    if (data is List) {
      return data.map((item) {
        // Mỗi item trong List là một Map chứa id, name, slug, iconKey
        return IncidentCategory.fromJson(item as Map<String, dynamic>);
      }).toList();
    }
    return [];
  }
}

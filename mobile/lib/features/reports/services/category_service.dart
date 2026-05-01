import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/incident_category.dart';

/// Service for fetching incident categories.
class CategoryService {
  final Dio _dio;
  final Duration _cacheTtl;
  List<IncidentCategory>? _cache;
  DateTime? _cacheTime;
  Future<List<IncidentCategory>>? _inFlightRequest;

  CategoryService({
    required Dio dio,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _dio = dio,
        _cacheTtl = cacheTtl;

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
  Future<List<IncidentCategory>> getCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedCategories = _validCachedCategories;
      if (cachedCategories != null) {
        return cachedCategories;
      }

      final inFlightRequest = _inFlightRequest;
      if (inFlightRequest != null) {
        return inFlightRequest;
      }
    }

    final request = _fetchAndCacheCategories(
      allowStaleOnError: !forceRefresh,
    );
    _inFlightRequest = request;
    return request;
  }

  void invalidateCache() {
    _cache = null;
    _cacheTime = null;
  }

  List<IncidentCategory>? get _validCachedCategories {
    final cache = _cache;
    final cacheTime = _cacheTime;
    if (cache == null || cacheTime == null) {
      return null;
    }

    final age = DateTime.now().difference(cacheTime);
    if (age >= _cacheTtl) {
      return null;
    }

    return List<IncidentCategory>.of(cache);
  }

  Future<List<IncidentCategory>> _fetchAndCacheCategories({
    required bool allowStaleOnError,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final categories = List<IncidentCategory>.of(
        _parseCategoryList(response.data),
      );
      _cache = categories;
      _cacheTime = DateTime.now();
      return List<IncidentCategory>.of(categories);
    } catch (_) {
      final cache = _cache;
      if (allowStaleOnError && cache != null) {
        return List<IncidentCategory>.of(cache);
      }
      rethrow;
    } finally {
      _inFlightRequest = null;
    }
  }
}

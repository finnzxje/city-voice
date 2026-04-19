import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/admin_category.dart';
import '../models/upsert_category_request.dart';
import '../models/user_manifest.dart';

class AdminService {
  final Dio _dio;

  AdminService({required Dio dio}) : _dio = dio;

  // ── User Management ────────────────────────────────────────────────────────

  /// Fetches all available system roles.
  Future<List<String>> getRoles() async {
    final response = await _dio.get(ApiConstants.adminRoles);
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<String>>.fromJson(
        data,
        fromJsonT: (json) =>
            (json as List).map((e) => (e as String).toLowerCase()).toList(),
      );
      return apiResponse.data ?? [];
    }

    // Fallback: direct list response.
    if (data is List) {
      return data.map((e) => (e as String).toLowerCase()).toList();
    }
    return [];
  }

  Future<List<UserManifest>> getUsers() async {
    final response = await _dio.get(ApiConstants.adminUsers);
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<UserManifest>>.fromJson(
        data,
        fromJsonT: (json) => (json as List)
            .map((e) => UserManifest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data ?? [];
    }

    if (data is List) {
      return data
          .map((e) => UserManifest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _dio.put(
      ApiConstants.adminUserRole(userId),
      data: {'role': role},
    );
  }

  // ── Category Management ────────────────────────────────────────────────────

  Future<List<AdminCategory>> getAllCategories() async {
    final response = await _dio.get(ApiConstants.allCategories);
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<List<AdminCategory>>.fromJson(
        data,
        fromJsonT: (json) => (json as List)
            .map((e) => AdminCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data ?? [];
    }

    if (data is List) {
      return data
          .map((e) => AdminCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AdminCategory> createCategory(UpsertCategoryRequest body) async {
    final response = await _dio.post(
      ApiConstants.categories,
      data: body.toJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return AdminCategory.fromJson(data['data'] as Map<String, dynamic>);
      }
      return AdminCategory.fromJson(data);
    }
    throw Exception('Unexpected response format');
  }

  Future<AdminCategory> updateCategory(
    int categoryId,
    UpsertCategoryRequest body,
  ) async {
    final response = await _dio.put(
      ApiConstants.categoryById(categoryId),
      data: body.toJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return AdminCategory.fromJson(data['data'] as Map<String, dynamic>);
      }
      return AdminCategory.fromJson(data);
    }
    throw Exception('Unexpected response format');
  }
}

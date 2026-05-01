import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_payload_parser.dart';
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
    return ApiPayloadParser.parseListValues(
      response.data,
      fromValue: (value) => (value as String).toLowerCase(),
    );
  }

  Future<List<UserManifest>> getUsers() async {
    final response = await _dio.get(ApiConstants.adminUsers);
    return ApiPayloadParser.parseList(
      response.data,
      fromJson: UserManifest.fromJson,
    );
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
    return ApiPayloadParser.parseList(
      response.data,
      fromJson: AdminCategory.fromJson,
    );
  }

  Future<AdminCategory> createCategory(UpsertCategoryRequest body) async {
    final response = await _dio.post(
      ApiConstants.categories,
      data: body.toJson(),
    );
    return AdminCategory.fromJson(
      ApiPayloadParser.requireObject(response.data),
    );
  }

  Future<AdminCategory> updateCategory(
    int categoryId,
    UpsertCategoryRequest body,
  ) async {
    final response = await _dio.put(
      ApiConstants.categoryById(categoryId),
      data: body.toJson(),
    );
    return AdminCategory.fromJson(
      ApiPayloadParser.requireObject(response.data),
    );
  }
}

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
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
}

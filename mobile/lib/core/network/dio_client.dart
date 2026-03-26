import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_helper.dart';
import 'api_response_interceptor.dart';
import 'token_interceptor.dart';

/// Factory that creates and configures the app-wide [Dio] instance.
///
/// Interceptor pipeline (order matters):
///  1. **TokenInterceptor** — attaches Bearer token, handles 401 refresh.
///  2. **ApiResponseInterceptor** — validates `ApiResponse.code`, maps errors.
///  3. **LogInterceptor** — (debug only) logs request/response for debugging.
class DioClient {
  DioClient._();

  /// Creates a fully configured [Dio] instance.
  ///
  /// Call this once in your dependency setup (e.g. from `main.dart`).
  static Dio create({required SecureStorageHelper storage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
        },
        // Allow Dio to resolve without throwing on non-2xx HTTP codes.
        // We handle status-code mapping in ApiResponseInterceptor instead.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // ── 1. Token management (must be first) ─────────────────────────────
    dio.interceptors.add(
      TokenInterceptor(storage: storage, dio: dio),
    );

    // ── 2. ApiResponse validation & error mapping ───────────────────────
    dio.interceptors.add(ApiResponseInterceptor());

    // ── 3. Logging (debug builds only) ──────────────────────────────────
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }

    return dio;
  }
}

import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_helper.dart';

/// Dio [Interceptor] that handles JWT authentication automatically.
///
/// **Request phase:**
///   Attaches `Authorization: Bearer <accessToken>` to every outgoing
///   request (except auth endpoints that don't require it).
///
/// **Error phase (401):**
///   1. Reads the stored `refreshToken`.
///   2. Calls `POST /auth/refresh` to obtain a new token pair.
///   3. Persists both new tokens via [SecureStorageHelper].
///   4. Retries the original failed request with the fresh access token.
///   5. If the refresh itself fails, clears storage and throws
///      [DioException] so the router can redirect to login.
///
/// A [Completer]-based lock prevents multiple concurrent refreshes
/// when parallel requests all fail with 401 simultaneously.
class TokenInterceptor extends Interceptor {
  final SecureStorageHelper _storage;
  final Dio _dio;

  /// Lock to prevent multiple simultaneous refresh attempts.
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  TokenInterceptor({
    required SecureStorageHelper storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  // ── Paths that should NOT carry the Authorization header ────────────────
  static final _publicPaths = {
    ApiConstants.citizenRegister,
    ApiConstants.citizenLogin,
    ApiConstants.citizenRequestOtp,
    ApiConstants.citizenVerifyOtp,
    ApiConstants.citizenVerifyEmail,
    ApiConstants.citizenResendVerification,
    ApiConstants.staffLogin,
    ApiConstants.refreshToken,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUEST — attach Bearer token
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;

    // Skip public / auth endpoints that don't need a token.
    final isPublic = _publicPaths.any((p) => path.endsWith(p));
    if (!isPublic) {
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR — handle 401 with automatic token refresh
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept 401 Unauthorized.
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't try to refresh if the failing request was the refresh itself.
    final failedPath = err.requestOptions.path;
    if (failedPath.endsWith(ApiConstants.refreshToken)) {
      await _storage.clearAll();
      return handler.next(err);
    }

    try {
      final newAccessToken = await _performTokenRefresh();

      if (newAccessToken == null) {
        // Refresh returned null → force logout.
        return handler.next(err);
      }

      // Retry the original request with the new token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await _dio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      // Retry also failed — propagate the error.
      return handler.next(retryError);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Token refresh logic with concurrency lock
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String?> _performTokenRefresh() async {
    // If another request is already refreshing, wait for it.
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearAll();
        _refreshCompleter!.complete(null);
        return null;
      }

      // Call the refresh endpoint using a plain Dio (no interceptor loop).
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          // Explicitly remove the old Authorization header.
          headers: {'Authorization': null},
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>?;

      if (data != null) {
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else {
        await _storage.clearAll();
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      // Refresh call failed — clear tokens and force re-login.
      await _storage.clearAll();
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}

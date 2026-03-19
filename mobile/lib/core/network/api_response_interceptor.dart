import 'dart:io';
import 'package:dio/dio.dart';
import 'api_exception.dart';

/// Dio [Interceptor] that transforms raw responses into typed exceptions.
///
/// **Response phase:**
///   Checks the `ApiResponse.code` field in the JSON body. If the code is
///   outside the 2xx range, it rejects with a properly typed [ApiException]
///   wrapped in a [DioException].
///
/// **Error phase:**
///   Converts network-level errors (socket, timeout, etc.) and HTTP error
///   responses into the appropriate [ApiException] subclass.
class ApiResponseInterceptor extends Interceptor {
  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSE — unwrap and validate ApiResponse.code
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    // If the response is a Map with our ApiResponse wrapper, validate `code`.
    if (data is Map<String, dynamic> && data.containsKey('code')) {
      final code = data['code'] as int;
      final message = data['message'] as String? ?? '';

      if (code < 200 || code >= 300) {
        // Extract field-level errors if present (400 validation).
        Map<String, dynamic>? fieldErrors;
        if (data['data'] is Map<String, dynamic>) {
          fieldErrors = data['data'] as Map<String, dynamic>;
        }

        final apiException = ApiException(
          code: code,
          message: message,
          fieldErrors: fieldErrors,
        );

        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: apiException,
          ),
        );
        return;
      }
    }

    handler.next(response);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR — map DioException types to ApiException subclasses
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If we already attached an ApiException, just pass it through.
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = const ServerException(
          message: 'Kết nối đến máy chủ bị quá thời gian.',
        );
        break;

      case DioExceptionType.connectionError:
        apiException = const NetworkException();
        break;

      case DioExceptionType.badResponse:
        apiException = _parseBadResponse(err.response);
        break;

      case DioExceptionType.cancel:
        apiException = const ApiException(
          code: 0,
          message: 'Yêu cầu đã bị huỷ.',
        );
        break;

      case DioExceptionType.unknown:
      default:
        if (err.error is SocketException) {
          apiException = const NetworkException();
        } else {
          apiException = ApiException(
            code: 0,
            message: err.message ?? 'Đã xảy ra lỗi không xác định.',
          );
        }
        break;
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }

  // ── Helper: parse error body from bad HTTP responses ─────────────────────
  ApiException _parseBadResponse(Response? response) {
    if (response == null) {
      return const ServerException();
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    // Attempt to extract message from the standard ApiResponse body.
    if (data is Map<String, dynamic>) {
      final code = data['code'] as int? ?? statusCode;
      final message = data['message'] as String? ?? 'Đã xảy ra lỗi.';

      Map<String, dynamic>? fieldErrors;
      if (data['data'] is Map<String, dynamic>) {
        fieldErrors = data['data'] as Map<String, dynamic>;
      }

      if (statusCode == 401) {
        return const SessionExpiredException();
      }

      return ApiException(
        code: code,
        message: message,
        fieldErrors: fieldErrors,
      );
    }

    // Fallback for non-JSON or unexpected responses.
    return ApiException(
      code: statusCode,
      message: 'Lỗi HTTP $statusCode',
    );
  }
}

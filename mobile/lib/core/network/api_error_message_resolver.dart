import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Resolves user-facing messages from Dio and API exceptions.
final class ApiErrorMessageResolver {
  const ApiErrorMessageResolver._();

  static String fromObject(
    Object error, {
    String fallback = 'Đã xảy ra lỗi không xác định.',
  }) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      return fromDioException(error, fallback: fallback);
    }

    return fallback;
  }

  static String fromDioException(
    DioException error, {
    String fallback = 'Đã xảy ra lỗi kết nối.',
  }) {
    final wrappedError = error.error;
    if (wrappedError is ApiException) {
      return wrappedError.message;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    final message = error.message;
    if (message != null && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }
}

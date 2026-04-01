/// Typed exception hierarchy for CityVoice API errors.
///
/// All API errors are wrapped in an [ApiException] so that ViewModels
/// and Services can pattern-match on the specific failure reason.
class ApiException implements Exception {
  final int code;

  final String message;

  /// Optional field-level validation errors.
  /// Present on `400` validation errors, e.g. `{ "email": "Email not valid" }`.
  final Map<String, dynamic>? fieldErrors;

  const ApiException({
    required this.code,
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thrown when the user's session has expired and could not be refreshed.
/// The app should redirect to the login screen.
class SessionExpiredException extends ApiException {
  const SessionExpiredException()
      : super(
          code: 401,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
}

/// Thrown when there is no network connectivity.
class NetworkException extends ApiException {
  const NetworkException()
      : super(
          code: 0,
          message: 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
        );
}

/// Thrown when the server is unreachable or times out.
class ServerException extends ApiException {
  const ServerException({String? message})
      : super(
          code: 503,
          message: message ?? 'Máy chủ không phản hồi. Vui lòng thử lại sau.',
        );
}

/// Thrown when a staff action is denied because the report is assigned
/// to someone else.
class ReportAssignmentException extends ApiException {
  const ReportAssignmentException({
    super.message =
        'Chỉ nhân viên được giao mới có thể thực hiện thao tác này.',
  }) : super(
          code: 403,
        );
}

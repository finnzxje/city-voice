/// Generic wrapper for all CityVoice API responses.
///
/// Every backend endpoint **should** return:
/// ```json
/// { "code": 200, "message": "...", "data": { ... } }
/// ```
///
/// However, the parsing is intentionally resilient: `code` defaults to `200`
/// when absent, and `message` defaults to `''`.
class ApiResponse<T> {
  /// Application-level status code (usually mirrors HTTP status).
  final int code;

  /// Human-readable message.
  final String message;

  /// The actual payload — may be `null` for error or void endpoints.
  final T? data;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// Whether this response represents a successful operation (2xx range).
  bool get isSuccess => code >= 200 && code < 300;

  /// Parses a raw JSON map into an [ApiResponse].
  ///
  /// If [fromJsonT] is provided, it will be used to deserialise `data`.
  /// If `data` is a [List], wrap [fromJsonT] with list logic at the call-site.
  ///
  /// **Null-safe**: `code` defaults to `200` when missing (some backend
  /// endpoints omit it on success).
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return ApiResponse<T>(
      code: (json['code'] as int?) ?? 200,
      message: (json['message'] as String?) ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}

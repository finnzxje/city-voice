/// Generic wrapper for all CityVoice API responses.
///
/// Error responses keep the same shape but `data` is `null` (or a
/// `Map<String, String>` of validation field errors for `400` responses).
class ApiResponse<T> {
  final int code;
  final String message;
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
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}

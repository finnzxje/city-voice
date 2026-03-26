import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../models/token_response.dart';
import '../models/user_info.dart';

/// Service layer for all authentication-related API calls.
///
/// Every parsing method is **resilient**: handles both the standard
/// `{ "code": 200, "data": { ... } }` wrapper format and flat responses
/// where the payload sits at the root level.
class AuthService {
  final Dio _dio;

  AuthService({required Dio dio}) : _dio = dio;

  // ═══════════════════════════════════════════════════════════════════════════
  // Citizen Registration & Verification
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registers a new citizen. On success, an OTP is sent to [email].
  Future<String> register({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    final response = await _dio.post(
      ApiConstants.citizenRegister,
      data: {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
    );
    return _extractMessage(response.data, 'Đăng ký thành công.');
  }

  /// Verifies the citizen's email with the OTP code.
  Future<String> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiConstants.citizenVerifyEmail,
      data: {'email': email, 'otp': otp},
    );
    return _extractMessage(response.data, 'Xác thực email thành công.');
  }

  /// Resends the email verification OTP.
  Future<String> resendVerification({required String email}) async {
    final response = await _dio.post(
      ApiConstants.citizenResendVerification,
      data: {'email': email},
    );
    return _extractMessage(response.data, 'Mã xác thực đã được gửi lại.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Citizen Login — Password
  // ═══════════════════════════════════════════════════════════════════════════

  /// Logs in a citizen with email + password.
  Future<TokenResponse> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.citizenLogin,
      data: {'email': email, 'password': password},
    );
    return _parseTokenResponse(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Citizen Login — OTP (passwordless)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Requests an OTP to be sent to the citizen's email for login.
  Future<String> requestLoginOtp({required String email}) async {
    final response = await _dio.post(
      ApiConstants.citizenRequestOtp,
      data: {'email': email},
    );
    return _extractMessage(response.data, 'Mã OTP đã được gửi.');
  }

  /// Verifies the login OTP and returns a token pair.
  Future<TokenResponse> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiConstants.citizenVerifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return _parseTokenResponse(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Staff / Manager / Admin Login
  // ═══════════════════════════════════════════════════════════════════════════

  /// Logs in a staff/manager/admin with email + password.
  Future<TokenResponse> staffLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.staffLogin,
      data: {'email': email, 'password': password},
    );
    return _parseTokenResponse(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Current User
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches the profile of the currently authenticated user.
  Future<UserInfo> fetchCurrentUser() async {
    final response = await _dio.get(ApiConstants.me);
    return _parseUserInfo(response.data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Logout
  // ═══════════════════════════════════════════════════════════════════════════

  /// Invalidates the refresh token server-side.
  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Swallow errors — we always clear local state regardless.
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers — resilient parsing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extracts message from either ApiResponse wrapper or plain response.
  String _extractMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  /// Parses a [TokenResponse] from the response body.
  ///
  /// Handles three possible formats:
  /// 1. Standard: `{ "code": 200, "data": { "accessToken": "...", ... } }`
  /// 2. Flat:     `{ "accessToken": "...", "refreshToken": "...", ... }`
  /// 3. Wrapped data without code: `{ "data": { "accessToken": "..." } }`
  TokenResponse _parseTokenResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      debugPrint(
          '[AuthService] Unexpected token response type: ${data.runtimeType}');
      throw Exception('Unexpected response format from server');
    }

    final map = data;

    // Case 1 & 3: token data nested under 'data' key
    if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
      final nested = map['data'] as Map<String, dynamic>;
      if (nested.containsKey('accessToken')) {
        return TokenResponse.fromJson(nested);
      }
    }

    // Case 2: token fields at root level
    if (map.containsKey('accessToken')) {
      return TokenResponse.fromJson(map);
    }

    debugPrint('[AuthService] Could not find token fields in response: $map');
    throw Exception('Invalid token response from server');
  }

  /// Parses a [UserInfo] from the response body.
  ///
  /// Handles both `{ "data": { ...user... } }` and flat `{ ...user... }`.
  UserInfo _parseUserInfo(dynamic data) {
    if (data is! Map<String, dynamic>) {
      debugPrint(
          '[AuthService] Unexpected user response type: ${data.runtimeType}');
      throw Exception('Unexpected response format from server');
    }

    final map = data;

    // Nested under 'data'
    if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
      final nested = map['data'] as Map<String, dynamic>;
      if (nested.containsKey('email') || nested.containsKey('id')) {
        return UserInfo.fromJson(nested);
      }
    }

    // Flat at root
    if (map.containsKey('email') || map.containsKey('id')) {
      return UserInfo.fromJson(map);
    }

    debugPrint('[AuthService] Could not find user fields in response: $map');
    throw Exception('Invalid user response from server');
  }
}

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../models/token_response.dart';
import '../models/user_info.dart';

/// Service layer for all authentication-related API calls.
///
/// Wraps Dio calls and returns domain-safe models. Throws
/// [ApiException] on failure (handled by the interceptor pipeline).
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<void>.fromJson(data);
      return apiResponse.message;
    }
    // Fallback for unexpected response formats.
    return data?.toString() ?? 'Đăng ký thành công.';
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<void>.fromJson(data);
      return apiResponse.message;
    }
    return data?.toString() ?? 'Xác thực email thành công.';
  }

  /// Resends the email verification OTP.
  Future<String> resendVerification({required String email}) async {
    final response = await _dio.post(
      ApiConstants.citizenResendVerification,
      data: {'email': email},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<void>.fromJson(data);
      return apiResponse.message;
    }
    return data?.toString() ?? 'Mã xác thực đã được gửi lại.';
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

    final apiResponse = ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => TokenResponse.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
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

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse<void>.fromJson(data);
      return apiResponse.message;
    }
    return data?.toString() ?? 'Mã OTP đã được gửi.';
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

    final apiResponse = ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => TokenResponse.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
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

    final apiResponse = ApiResponse<TokenResponse>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => TokenResponse.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Current User
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches the profile of the currently authenticated user.
  Future<UserInfo> fetchCurrentUser() async {
    final response = await _dio.get(ApiConstants.me);

    final apiResponse = ApiResponse<UserInfo>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => UserInfo.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
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
}

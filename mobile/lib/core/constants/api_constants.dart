/// Centralised API configuration and endpoint paths.
///
/// All paths are relative to [baseUrl]. The [baseUrl] defaults to
/// `http://10.0.2.2:8080/api` which routes to the host machine's
/// `localhost:8080` when running inside the Android emulator.
///
/// For physical device testing, change [baseUrl] to your machine's
/// LAN IP, e.g. `http://192.168.1.X:8080/api`.
library;

class ApiConstants {
  ApiConstants._(); // prevent instantiation

  // ── Base URL ───────────────────────────────────────────────────────────────
  /// Default base URL for the CityVoice Spring Boot backend.
  /// Override via environment variable or a settings screen in the future.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.251.2.222:8080/api',
  );

  // ── Auth endpoints ─────────────────────────────────────────────────────────
  static const String citizenRegister = '/auth/citizen/register';
  static const String citizenLogin = '/auth/citizen/login';
  static const String citizenRequestOtp = '/auth/citizen/request-otp';
  static const String citizenVerifyOtp = '/auth/citizen/verify-otp';
  static const String citizenVerifyEmail = '/auth/citizen/verify-email';
  static const String citizenResendVerification =
      '/auth/citizen/resend-verification';
  static const String staffLogin = '/auth/staff/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── Report endpoints ───────────────────────────────────────────────────────
  static const String reports = '/reports';
  static const String myReports = '/reports/my';

  /// Returns the path for a specific report.
  static String reportById(String id) => '/reports/$id';

  /// Returns the path to review a report (newly_received → in_progress).
  static String reviewReport(String id) => '/reports/$id/review';

  /// Returns the path to reject a report (newly_received → rejected).
  static String rejectReport(String id) => '/reports/$id/reject';

  /// Returns the path to resolve a report (in_progress → resolved).
  static String resolveReport(String id) => '/reports/$id/resolve';

  // ── Category endpoints ─────────────────────────────────────────────────────
  static const String categories = '/categories';

  // ── Notification endpoints ─────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';

  /// Returns the path to mark a notification as read.
  static String markNotificationRead(String id) => '/notifications/$id/read';
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper for persisting JWT tokens (access + refresh).
///
/// Uses [FlutterSecureStorage] backed by:
///  - **Android**: EncryptedSharedPreferences
///  - **iOS**: Keychain
///
/// This class is a singleton consumed by [TokenInterceptor] and
/// [AuthViewModel].
class SecureStorageHelper {
  // Keys —————————————————————————————————————————————————————————
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorageHelper({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Access Token ─────────────────────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  // ── Refresh Token ────────────────────────────────────────────────────────
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);

  // ── Convenience ──────────────────────────────────────────────────────────

  /// Persists both tokens at once after a login or refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Returns `true` if an access token is present (quick auth check).
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Wipes all stored tokens — used on logout or session expiry.
  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }
}

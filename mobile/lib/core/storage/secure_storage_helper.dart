import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper for persisting JWT tokens (access + refresh).
///
/// Uses [FlutterSecureStorage] backed by:
///  - **Android**: EncryptedSharedPreferences
///  - **iOS**: Keychain
///
/// This class is a singleton consumed by [TokenInterceptor] and
/// [AuthViewModel].
class SecureStorageHelper extends ChangeNotifier {
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

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    notifyListeners();
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
    notifyListeners();
  }

  // ── Refresh Token ────────────────────────────────────────────────────────
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    notifyListeners();
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
    notifyListeners();
  }

  // ── Convenience ──────────────────────────────────────────────────────────

  /// Persists both tokens at once after a login or refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    notifyListeners();
  }

  /// Returns `true` if an access token is present (quick auth check).
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Wipes all stored tokens — used on logout or session expiry.
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:io';

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
  static const _cachedUserProfileKey = 'cached_user_profile';
  static const _sessionPresenceFileName = 'city_voice_session_presence';

  final FlutterSecureStorage _storage;
  String? _accessTokenCache;
  String? _refreshTokenCache;
  String? _cachedUserProfileCache;
  bool _hasAccessTokenCache = false;
  bool _hasRefreshTokenCache = false;
  bool _hasCachedUserProfileCache = false;
  bool? _hasTokensCache;
  bool? _sessionPresenceHintCache;
  bool _hasSessionPresenceHintCache = false;

  SecureStorageHelper({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Access Token ─────────────────────────────────────────────────────────
  Future<String?> getAccessToken() async {
    if (_hasAccessTokenCache) {
      return _accessTokenCache;
    }

    final token = await _storage.read(key: _accessTokenKey);
    _cacheAccessToken(token);
    return token;
  }

  Future<void> saveAccessToken(String token) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: token),
      _persistSessionPresenceHint(true),
    ]);
    _cacheAccessToken(token);
    notifyListeners();
  }

  Future<void> deleteAccessToken() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _persistSessionPresenceHint(false),
    ]);
    _cacheAccessToken(null);
    notifyListeners();
  }

  // ── Refresh Token ────────────────────────────────────────────────────────
  Future<String?> getRefreshToken() async {
    if (_hasRefreshTokenCache) {
      return _refreshTokenCache;
    }

    final token = await _storage.read(key: _refreshTokenKey);
    _cacheRefreshToken(token);
    return token;
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    _cacheRefreshToken(token);
    notifyListeners();
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
    _cacheRefreshToken(null);
    notifyListeners();
  }

  // ── Cached User Profile ──────────────────────────────────────────────────
  Future<String?> getCachedUserProfile() async {
    if (_hasCachedUserProfileCache) {
      return _cachedUserProfileCache;
    }

    final profile = await _storage.read(key: _cachedUserProfileKey);
    _cacheCachedUserProfile(profile);
    return profile;
  }

  Future<void> saveCachedUserProfile(String profileJson) async {
    await _storage.write(key: _cachedUserProfileKey, value: profileJson);
    _cacheCachedUserProfile(profileJson);
  }

  Future<void> deleteCachedUserProfile() async {
    await _storage.delete(key: _cachedUserProfileKey);
    _cacheCachedUserProfile(null);
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
      _persistSessionPresenceHint(true),
    ]);
    _cacheAccessToken(accessToken);
    _cacheRefreshToken(refreshToken);
    notifyListeners();
  }

  Future<bool?> getSessionPresenceHint() async {
    if (_hasSessionPresenceHintCache) {
      return _sessionPresenceHintCache;
    }

    try {
      final file = await _getSessionPresenceFile();
      if (!await file.exists()) {
        _cacheSessionPresenceHint(null);
        return null;
      }

      final rawValue = (await file.readAsString()).trim();
      final value = switch (rawValue) {
        '1' => true,
        '0' => false,
        _ => null,
      };

      if (value == null) {
        await file.delete();
      }

      _cacheSessionPresenceHint(value);
      return value;
    } catch (_) {
      return null;
    }
  }

  bool? readSessionPresenceHintSync() {
    if (_hasSessionPresenceHintCache) {
      return _sessionPresenceHintCache;
    }

    try {
      final file = _getSessionPresenceFileSync();
      if (!file.existsSync()) {
        _cacheSessionPresenceHint(null);
        return null;
      }

      final rawValue = file.readAsStringSync().trim();
      final value = switch (rawValue) {
        '1' => true,
        '0' => false,
        _ => null,
      };

      if (value == null && file.existsSync()) {
        file.deleteSync();
      }

      _cacheSessionPresenceHint(value);
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` if an access token is present (quick auth check).
  Future<bool> hasTokens() async {
    final cachedValue = _hasTokensCache;
    if (cachedValue != null) {
      return cachedValue;
    }

    if (_hasAccessTokenCache) {
      final hasTokens = _hasNonEmptyValue(_accessTokenCache);
      _hasTokensCache = hasTokens;
      return hasTokens;
    }

    final sessionPresenceHint = await getSessionPresenceHint();
    if (sessionPresenceHint != null) {
      _hasTokensCache = sessionPresenceHint;
      if (!sessionPresenceHint) {
        _cacheAccessToken(null);
      }
      return sessionPresenceHint;
    }

    final hasToken = await _storage.containsKey(key: _accessTokenKey);
    await _persistSessionPresenceHint(hasToken);

    if (!hasToken) {
      _cacheAccessToken(null);
      return false;
    }

    _hasTokensCache = true;
    return true;
  }

  /// Wipes all stored tokens — used on logout or session expiry.
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _cachedUserProfileKey),
      _persistSessionPresenceHint(false),
    ]);
    _cacheAccessToken(null);
    _cacheRefreshToken(null);
    _cacheCachedUserProfile(null);
    notifyListeners();
  }

  void _cacheAccessToken(String? token) {
    _accessTokenCache = token;
    _hasAccessTokenCache = true;
    _hasTokensCache = _hasNonEmptyValue(token);
  }

  void _cacheRefreshToken(String? token) {
    _refreshTokenCache = token;
    _hasRefreshTokenCache = true;
  }

  void _cacheCachedUserProfile(String? profile) {
    _cachedUserProfileCache = profile;
    _hasCachedUserProfileCache = true;
  }

  void _cacheSessionPresenceHint(bool? value) {
    _sessionPresenceHintCache = value;
    _hasSessionPresenceHintCache = true;
  }

  Future<void> _persistSessionPresenceHint(bool value) async {
    _cacheSessionPresenceHint(value);
    try {
      final file = await _getSessionPresenceFile();
      await file.writeAsString(value ? '1' : '0', flush: true);
    } catch (_) {
      // Ignore sidecar persistence failures. Secure storage remains source of truth.
    }
  }

  Future<File> _createSessionPresenceFile() async {
    return _getSessionPresenceFileSync();
  }

  File _getSessionPresenceFileSync() =>
      File('${Directory.systemTemp.path}/$_sessionPresenceFileName');

  Future<File> _getSessionPresenceFile() => _createSessionPresenceFile();

  bool _hasNonEmptyValue(String? value) => value != null && value.isNotEmpty;
}

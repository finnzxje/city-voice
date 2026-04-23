import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error_message_resolver.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_helper.dart';
import '../models/user_info.dart';
import '../services/auth_service.dart';

/// Exposes the current [user], loading/error states, and all auth actions.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageHelper _storage;

  AuthViewModel({
    required AuthService authService,
    required SecureStorageHelper storage,
  })  : _authService = authService,
        _storage = storage {
    _storage.addListener(_handleStorageChanged);
  }

  // ── Observable state ───────────────────────────────────────────────────────
  UserInfo? _user;
  UserInfo? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isRestoringSession = true;

  bool get isRestoringSession => _isRestoringSession;

  /// Whether the OTP was already sent (for OTP login mode).
  bool _otpSent = false;
  bool get otpSent => _otpSent;

  // ── Private helpers ────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetOtpState() {
    _otpSent = false;
    notifyListeners();
  }

  void _handleStorageChanged() {
    _syncAuthStateWithStorage();
  }

  Future<void> _syncAuthStateWithStorage() async {
    final hasToken = await _storage.hasTokens();
    if (hasToken) return;

    await _storage.deleteCachedUserProfile();

    final shouldNotify =
        _user != null || _isAuthenticated || _otpSent || _errorMessage != null;

    _user = null;
    _isAuthenticated = false;
    _otpSent = false;
    _errorMessage = null;
    _successMessage = null;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  // ── Citizen Registration ────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final message = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      _setSuccess(message);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    }
  }

  // ── Email Verification ─────────────────────────────────────────────────
  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final message = await _authService.verifyEmail(email: email, otp: otp);
      _setSuccess(message);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    }
  }

  /// Resends the email-verification OTP.
  Future<void> resendVerification({required String email}) async {
    _setLoading(true);
    _setError(null);
    try {
      final message = await _authService.resendVerification(email: email);
      _setSuccess(message);
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    } finally {
      _setLoading(false);
    }
  }

  // ── Citizen Login — Password ───────────────────────────────────────────
  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final tokenResponse = await _authService.loginWithPassword(
        email: email,
        password: password,
      );
      await _storage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      await _fetchAndSetUser();
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      // Check if the error is 403 "account inactive" → need verification.
      if (e.error is ApiException) {
        final apiError = e.error as ApiException;
        if (apiError.code == 403) {
          _setError(apiError.message);
          _setLoading(false);
          // Return false but the caller can check errorMessage for 403.
          return false;
        }
      }
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    }
  }

  // ── Citizen Login — OTP (passwordless) ─────────────────────────────────
  Future<void> requestLoginOtp({required String email}) async {
    _setLoading(true);
    _setError(null);
    try {
      final message = await _authService.requestLoginOtp(email: email);
      _otpSent = true;
      _setSuccess(message);
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final tokenResponse = await _authService.verifyLoginOtp(
        email: email,
        otp: otp,
      );
      await _storage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      await _fetchAndSetUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    }
  }

  // ── Staff Login ────────────────────────────────────────────────────────
  Future<bool> staffLogin({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final tokenResponse = await _authService.staffLogin(
        email: email,
        password: password,
      );
      await _storage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      await _fetchAndSetUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(ApiErrorMessageResolver.fromObject(e));
      _setLoading(false);
      return false;
    }
  }

  // ── Try restoring session from stored tokens ───────────────────────────
  Future<void> tryAutoLogin() async {
    try {
      final sessionPresenceHint = await _storage.getSessionPresenceHint();
      if (sessionPresenceHint != true) {
        _clearAuthState(notify: false);
        return;
      }

      final hasToken = await _storage.hasTokens();
      if (!hasToken) {
        _clearAuthState(notify: false);
        return;
      }

      final cachedUser = await _restoreCachedUser();
      if (cachedUser != null) {
        _applyAuthenticatedUser(cachedUser, notify: false);
        _isRestoringSession = false;
        notifyListeners();
        unawaited(_refreshCurrentUserInBackground());
        return;
      }

      _isAuthenticated = true;
      _isRestoringSession = false;
      notifyListeners();
      unawaited(_refreshCurrentUserInBackground());
    } catch (_) {
      // Token likely expired and couldn't refresh — clear state.
      await _storage.clearAll();
      _clearAuthState(notify: false);
    } finally {
      if (_isRestoringSession) {
        _isRestoringSession = false;
        notifyListeners();
      }
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      await _authService.logout(refreshToken: refreshToken);
    }
    await _storage.clearAll();
    _user = null;
    _isAuthenticated = false;
    _otpSent = false;
    clearMessages();
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────
  Future<void> _fetchAndSetUser() async {
    final user = await _authService.fetchCurrentUser();
    _applyAuthenticatedUser(user, notify: true);
    await _storage.saveCachedUserProfile(jsonEncode(user.toJson()));
  }

  Future<UserInfo?> _restoreCachedUser() async {
    final cachedProfile = await _storage.getCachedUserProfile();
    if (cachedProfile == null || cachedProfile.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cachedProfile);
      if (decoded is! Map) {
        await _storage.deleteCachedUserProfile();
        return null;
      }

      return UserInfo.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await _storage.deleteCachedUserProfile();
      return null;
    }
  }

  Future<void> _refreshCurrentUserInBackground() async {
    try {
      await _fetchAndSetUser();
    } on DioException catch (error) {
      final wrappedError = error.error;
      final shouldInvalidateSession = wrappedError is SessionExpiredException ||
          (wrappedError is ApiException && wrappedError.code == 401);

      if (shouldInvalidateSession) {
        await _storage.clearAll();
        _clearAuthState();
      }
    } catch (_) {
      // Preserve the cached user for transient startup/network failures.
    }
  }

  void _applyAuthenticatedUser(
    UserInfo user, {
    required bool notify,
  }) {
    _user = user;
    _isAuthenticated = true;
    if (notify) {
      notifyListeners();
    }
  }

  void _clearAuthState({bool notify = true}) {
    _user = null;
    _isAuthenticated = false;
    _otpSent = false;
    _errorMessage = null;
    _successMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _storage.removeListener(_handleStorageChanged);
    super.dispose();
  }
}

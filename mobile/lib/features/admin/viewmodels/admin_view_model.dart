import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../models/user_manifest.dart';
import '../services/admin_service.dart';

/// View states for async operations.
enum ViewState { idle, loading, success, error }

class AdminViewModel extends ChangeNotifier {
  final AdminService _adminService;

  AdminViewModel({required AdminService adminService})
      : _adminService = adminService;

  // ── User state ─────────────────────────────────────────────────────────────
  List<UserManifest> _users = [];

  List<UserManifest> get users => _users;

  List<String> _availableRoles = [];

  List<String> get availableRoles => _availableRoles;

  ViewState _usersState = ViewState.idle;

  ViewState get usersState => _usersState;

  // ── Shared action state ────────────────────────────────────────────────────
  ViewState _actionState = ViewState.idle;

  ViewState get actionState => _actionState;

  String? _actionError;

  String? get actionError => _actionError;

  String? _usersError;

  String? get usersError => _usersError;

  String? _categoriesError;

  String? get categoriesError => _categoriesError;

  // ═══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Loads roles and users concurrently.
  Future<void> loadUsers() async {
    _usersState = ViewState.loading;
    _usersError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _adminService.getRoles(),
        _adminService.getUsers(),
      ]);
      _availableRoles = List<String>.from(results[0] as List<String>)..sort();
      _users = _sortUsers(results[1] as List<UserManifest>);
      _usersState = ViewState.success;
    } catch (e) {
      _usersError = _extractError(e);
      _usersState = ViewState.error;
    }
    notifyListeners();
  }

  /// Updates a user's role. On success, updates the local list in-place.
  Future<bool> updateUserRole(String userId, String newRole) async {
    _actionState = ViewState.loading;
    _actionError = null;
    notifyListeners();

    try {
      await _adminService.updateUserRole(userId, newRole);
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx >= 0) {
        _users = List<UserManifest>.from(_users)
          ..[idx] = _users[idx].copyWith(role: newRole);
      }
      _actionState = ViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = _extractError(e);
      _actionState = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<UserManifest> _sortUsers(List<UserManifest> users) {
    final sorted = List<UserManifest>.from(users);
    sorted.sort((a, b) {
      final roleCompare = a.role.compareTo(b.role);
      if (roleCompare != 0) return roleCompare;

      final nameCompare = a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          );
      if (nameCompare != 0) return nameCompare;

      return a.email.toLowerCase().compareTo(b.email.toLowerCase());
    });
    return sorted;
  }

  String _extractError(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Đã xảy ra lỗi';
      }
      return e.message ?? 'Lỗi kết nối';
    }
    if (e is ApiException) return e.message;
    return 'Đã xảy ra lỗi không xác định';
  }
}

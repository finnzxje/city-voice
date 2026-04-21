import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_error_message_resolver.dart';
import '../models/admin_category.dart';
import '../models/upsert_category_request.dart';
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

  // ── Category state ─────────────────────────────────────────────────────────
  List<AdminCategory> _categories = [];

  List<AdminCategory> get categories => _categories;

  ViewState _categoriesState = ViewState.idle;

  ViewState get categoriesState => _categoriesState;

  // ── Shared action state ────────────────────────────────────────────────────
  ViewState _actionState = ViewState.idle;

  ViewState get actionState => _actionState;

  String? _actionError;

  String? get actionError => _actionError;

  String? _usersError;

  String? get usersError => _usersError;

  String? _categoriesError;

  String? get categoriesError => _categoriesError;

  // ── Filter state ───────────────────────────────────────────────────────────
  String _searchQuery = '';
  String? _roleFilter;

  String get searchQuery => _searchQuery;

  String? get roleFilter => _roleFilter;

  List<UserManifest> get filteredUsers {
    return _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter == null || user.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String? role) {
    _roleFilter = role;
    notifyListeners();
  }

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
      _usersError = ApiErrorMessageResolver.fromObject(e);
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
      _actionError = ApiErrorMessageResolver.fromObject(e);
      _actionState = ViewState.error;
      notifyListeners();
      return false;
    }
  }

// ═══════════════════════════════════════════════════════════════════════════
// CATEGORY MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

  /// Loads all categories (including inactive).
  Future<void> loadCategories() async {
    _categoriesState = ViewState.loading;
    _categoriesError = null;
    notifyListeners();

    try {
      final fetchedCategories = await _adminService.getAllCategories();
      _categories = _sortCategories(fetchedCategories);
      _categoriesState = ViewState.success;
    } catch (e) {
      _categoriesError = ApiErrorMessageResolver.fromObject(e);
      _categoriesState = ViewState.error;
    }
    notifyListeners();
  }

  Future<bool> createCategory(UpsertCategoryRequest req) async {
    _actionState = ViewState.loading;
    _actionError = null;
    notifyListeners();

    try {
      final created = await _adminService.createCategory(req);
      _categories = _sortCategories([created, ..._categories]);
      _actionState = ViewState.success;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        _actionError = 'Slug này đã tồn tại';
      } else {
        _actionError = ApiErrorMessageResolver.fromObject(e);
      }
      _actionState = ViewState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _actionError = ApiErrorMessageResolver.fromObject(e);
      _actionState = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, UpsertCategoryRequest req) async {
    _actionState = ViewState.loading;
    _actionError = null;
    notifyListeners();

    try {
      final updated = await _adminService.updateCategory(id, req);
      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx >= 0) {
        _categories = _sortCategories(
          List<AdminCategory>.from(_categories)..[idx] = updated,
        );
      } else {
        _categories = _sortCategories([updated, ..._categories]);
      }
      _actionState = ViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = ApiErrorMessageResolver.fromObject(e);
      _actionState = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  /// Convenience: toggles a category's active flag.
  Future<bool> toggleCategoryActive(AdminCategory cat) {
    return updateCategory(
      cat.id,
      UpsertCategoryRequest(
        name: cat.name,
        slug: cat.slug,
        iconKey: cat.iconKey,
        active: !cat.active,
      ),
    );
  }

  /// Clears the action error (e.g. when retrying).
  void clearActionError() {
    _actionError = null;
    notifyListeners();
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

  List<AdminCategory> _sortCategories(List<AdminCategory> categories) {
    final sorted = List<AdminCategory>.from(categories);
    sorted.sort((a, b) {
      if (a.active != b.active) {
        return a.active ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }
}

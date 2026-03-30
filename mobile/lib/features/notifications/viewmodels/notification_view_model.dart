import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationViewModel({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  // ── Observable state ───────────────────────────────────────────────────────

  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  final ListQueue<NotificationModel> _pendingPushNotifications = ListQueue();
  Timer? _pollTimer;
  bool _initialized = false;
  bool _isPolling = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Call once after the user is authenticated.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await refresh();

    // Start polling every 30 seconds for new notifications.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollForNewNotifications(),
    );
  }

  // ── Load data ──────────────────────────────────────────────────────────────

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final snapshot = await _fetchSnapshot();
      _applySnapshot(snapshot);
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Silent — badge will just show 0.
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  Future<void> _pollForNewNotifications() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final snapshot = await _fetchSnapshot();
      final previousIds = _notifications.map((n) => n.id).toSet();
      final freshNotifications = snapshot.notifications
          .where((n) => !previousIds.contains(n.id) && !n.isRead)
          .toList();

      _applySnapshot(snapshot);
      _queuePushNotifications(freshNotifications);
    } catch (_) {
      // Silent — don't disrupt the user.
    } finally {
      _isPolling = false;
    }
  }

  void _queuePushNotifications(List<NotificationModel> notifications) {
    if (notifications.isEmpty) return;

    _pendingPushNotifications.addAll(notifications);
    notifyListeners();
  }

  NotificationModel? takeNextPushNotification() {
    if (_pendingPushNotifications.isEmpty) {
      return null;
    }

    return _pendingPushNotifications.removeFirst();
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _notificationService.markAsRead(notifId);

      final index = _notifications.indexWhere((n) => n.id == notifId);
      if (index >= 0 && !_notifications[index].isRead) {
        _notifications = List<NotificationModel>.from(_notifications)
          ..[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotifVM] markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();

    if (unreadIds.isEmpty) return;

    await Future.wait(
      unreadIds.map((id) => _notificationService.markAsRead(id)),
    );

    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  /// Stops polling. Call when user logs out.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _initialized = false;
    _isPolling = false;
    _notifications = [];
    _unreadCount = 0;
    _errorMessage = null;
    _pendingPushNotifications.clear();
    notifyListeners();
  }

  Future<_NotificationSnapshot> _fetchSnapshot() async {
    final results = await Future.wait<Object>([
      _notificationService.getNotifications(),
      _notificationService.getUnreadCount(),
    ]);

    return _NotificationSnapshot(
      notifications: results[0] as List<NotificationModel>,
      unreadCount: results[1] as int,
    );
  }

  void _applySnapshot(_NotificationSnapshot snapshot) {
    final shouldNotify = _errorMessage != null ||
        _unreadCount != snapshot.unreadCount ||
        _hasNotificationListChanged(snapshot.notifications);

    _notifications = snapshot.notifications;
    _unreadCount = snapshot.unreadCount;
    _errorMessage = null;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  bool _hasNotificationListChanged(List<NotificationModel> next) {
    if (_notifications.length != next.length) {
      return true;
    }

    for (var i = 0; i < next.length; i++) {
      final current = _notifications[i];
      final candidate = next[i];
      if (current.id != candidate.id ||
          current.isRead != candidate.isRead ||
          current.message != candidate.message ||
          current.type != candidate.type ||
          current.sentAt != candidate.sentAt ||
          current.createdAt != candidate.createdAt ||
          current.reportId != candidate.reportId) {
        return true;
      }
    }

    return false;
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 'Đã xảy ra lỗi';
    }
    return e.message ?? 'Đã xảy ra lỗi kết nối';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class _NotificationSnapshot {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const _NotificationSnapshot({
    required this.notifications,
    required this.unreadCount,
  });
}

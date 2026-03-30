import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/notification_view_model.dart';
import 'in_app_push_banner.dart';

class NotificationOverlayListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const NotificationOverlayListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<NotificationOverlayListener> createState() =>
      _NotificationOverlayListenerState();
}

class _NotificationOverlayListenerState
    extends State<NotificationOverlayListener> {
  NotificationViewModel? _viewModel;
  OverlayEntry? _activeEntry;
  bool _isShowingBanner = false;
  bool _retryScheduled = false;
  NotificationModel? _stagedNotification;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextViewModel = context.read<NotificationViewModel>();
    if (_viewModel == nextViewModel) {
      return;
    }

    _viewModel?.removeListener(_handleNotificationChange);
    _viewModel = nextViewModel;
    _viewModel?.addListener(_handleNotificationChange);
  }

  void _handleNotificationChange() {
    if (_isShowingBanner) return;

    final notification =
        _stagedNotification ?? _viewModel?.takeNextPushNotification();
    if (notification == null) return;

    _isShowingBanner = true;
    _stagedNotification = notification;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isShowingBanner = false;
        return;
      }

      final overlay = widget.navigatorKey.currentState?.overlay;
      if (overlay == null) {
        _isShowingBanner = false;
        _scheduleRetry();
        return;
      }

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => InAppPushBanner(
          notification: notification,
          onDismiss: () => _dismissBanner(entry),
        ),
      );

      _activeEntry = entry;
      _stagedNotification = null;
      overlay.insert(entry);
    });
  }

  void _scheduleRetry() {
    if (_retryScheduled) return;

    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted) {
        _handleNotificationChange();
      }
    });
  }

  void _dismissBanner(OverlayEntry entry) {
    if (_activeEntry == entry) {
      _activeEntry = null;
    }

    try {
      entry.remove();
    } catch (_) {}

    _isShowingBanner = false;
    _handleNotificationChange();
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleNotificationChange);
    _activeEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

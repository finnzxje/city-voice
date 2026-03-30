import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../models/notification_model.dart';
import '../viewmodels/notification_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        actions: [
          Consumer<NotificationViewModel>(
            builder: (_, vm, __) {
              if (vm.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => vm.markAllAsRead(),
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.errorMessage != null && vm.notifications.isEmpty) {
            return _buildErrorState(theme, vm);
          }

          if (vm.notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () => vm.refresh(showLoading: false),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vm.notifications.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final notif = vm.notifications[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () => _onNotificationTap(context, vm, notif),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    NotificationViewModel vm,
    NotificationModel notification,
  ) {
    // Mark as read if unread.
    if (!notification.isRead) {
      vm.markAsRead(notification.id);
    }

    // Navigate to report detail.
    if (notification.reportId != null) {
      context.push('/reports/${notification.reportId}');
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo nào',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn sẽ nhận được thông báo khi báo cáo được xử lý',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, NotificationViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            vm.errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => vm.loadNotifications(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final typeIcon = _typeIcon(notification.type);
    final typeColor = _typeColor(notification.type);

    return Material(
      color: isUnread ? const Color(0xFFE3F2FD) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),

              // ── Content ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(notification.displayDate,
                              locale: 'vi'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Unread dot ────────────────────────────
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'report_resolved' => Icons.check_circle_outline_rounded,
      'report_rejected' => Icons.cancel_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'report_resolved' => AppColors.success,
      'report_rejected' => AppColors.error,
      _ => AppColors.primary,
    };
  }
}

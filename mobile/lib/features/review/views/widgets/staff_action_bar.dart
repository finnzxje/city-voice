import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_view_model.dart';
import '../../../reports/models/report.dart';

/// Bottom action bar that changes based on report status.
class StaffActionBar extends StatelessWidget {
  final Report report;
  final VoidCallback onReview;
  final VoidCallback onReject;
  final VoidCallback onResolve;

  const StaffActionBar({
    super.key,
    required this.report,
    required this.onReview,
    required this.onReject,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final status = report.currentStatus;
    final authVm = context.read<AuthViewModel>();
    final currentUserId = authVm.user?.id;
    final currentUserRole = authVm.user?.role;
    final canResolve = currentUserRole == UserRole.admin ||
        (currentUserId != null &&
            report.assignedToId != null &&
            report.assignedToId == currentUserId);

    if (status == 'resolved') {
      return _StatusBanner(
        icon: Icons.check_circle,
        text:
            'Đã giải quyết vào ${DateFormat('dd/MM/yyyy').format(report.resolvedAt ?? report.updatedAt ?? DateTime.now())}',
        color: AppColors.success,
        bgColor: AppColors.statusResolvedBg,
      );
    }

    if (status == 'rejected') {
      return _StatusBanner(
        icon: Icons.cancel,
        text: 'Báo cáo đã bị từ chối',
        color: AppColors.error,
        bgColor: AppColors.statusRejectedBg,
      );
    }

    if (status == 'newly_received') {
      return _ActionContainer(
        child: Row(
          children: [
            Expanded(
              child: ActionButton(
                label: 'Từ chối',
                icon: Icons.close,
                color: Colors.white,
                textColor: const Color(0xFF111827),
                isOutlined: true,
                onTap: onReject,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ActionButton(
                label: 'Duyệt',
                icon: Icons.check,
                color: const Color(0xFF0044CC),
                textColor: Colors.white,
                onTap: onReview,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'in_progress') {
      return _ActionContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canResolve) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.warning.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chỉ nhân viên được giao mới có thể xác nhận hoàn thành.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ActionButton(
              label: 'Xác nhận hoàn thành',
              icon: Icons.check_circle,
              color: const Color(0xFF0044CC),
              textColor: Colors.white,
              onTap: canResolve
                  ? onResolve
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Chỉ nhân viên được giao mới có thể thực hiện thao tác này.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
              isFullWidth: true,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Status Banner ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bgColor;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: color.withOpacity(0.3))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Container ────────────────────────────────────────────────────────

class _ActionContainer extends StatelessWidget {
  final Widget child;

  const _ActionContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
      ),
      child: child,
    );
  }
}

// ─── Reusable Action Button ──────────────────────────────────────────────────

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool isOutlined;
  final bool isFullWidth;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.isOutlined = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        height: 54,
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            backgroundColor: color,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

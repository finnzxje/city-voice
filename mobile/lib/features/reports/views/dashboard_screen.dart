import 'package:city_voice/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../models/report.dart';
import '../viewmodels/report_view_model.dart';

/// Main dashboard screen for citizens.
///
/// Shows a greeting, stats summary cards, notification badge,
/// a list of the citizen's reports, and a FAB to submit a new report.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Consumer<ReportViewModel>(
          builder: (context, vm, _) {
            return RefreshIndicator(
              onRefresh: vm.refreshReports,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── Header ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(theme, authVm, vm),
                  ),

                  // ── Stats Cards ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildStatsRow(theme, vm),
                  ),

                  // ── Section Title ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Báo cáo của tôi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${vm.reports.length} báo cáo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Loading / Error / Empty / Report List ────────────
                  if (vm.isLoading && vm.reports.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (vm.errorMessage != null && vm.reports.isEmpty)
                    SliverFillRemaining(
                      child: _buildErrorState(theme, vm),
                    )
                  else if (vm.reports.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(theme),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: vm.reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _ReportCard(report: vm.reports[index]),
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reports/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit_outlined, size: 26),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
      ThemeData theme, AuthViewModel authVm, ReportViewModel vm) {
    final name = authVm.user?.fullName ?? 'Cư dân';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: open notification panel
                },
                icon: const Icon(Icons.notifications_outlined),
                iconSize: 28,
                color: AppColors.textPrimary,
              ),
              if (vm.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      vm.unreadCount > 9 ? '9+' : '${vm.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            onPressed: () async {
              final authVm = context.read<AuthViewModel>();
              final router = GoRouter.of(context);
              await authVm.logout();
              router.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ReportViewModel vm) {
    final total = vm.reports.length;
    final newCount =
        vm.reports.where((r) => r.currentStatus == 'newly_received').length;
    final inProgressCount =
        vm.reports.where((r) => r.currentStatus == 'in_progress').length;
    final resolvedCount =
        vm.reports.where((r) => r.currentStatus == 'resolved').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Tổng',
            count: total,
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Mới',
            count: newCount,
            color: AppColors.statusNew,
            bgColor: AppColors.statusNewBg,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Đang xử lý',
            count: inProgressCount,
            color: AppColors.statusInProgress,
            bgColor: AppColors.statusInProgressBg,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Hoàn thành',
            count: resolvedCount,
            color: AppColors.statusResolved,
            bgColor: AppColors.statusResolvedBg,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có báo cáo nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn nút "Báo cáo mới" để gửi sự cố đầu tiên',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ReportViewModel vm) {
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
            onPressed: () => vm.loadDashboard(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Card ─────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(report.currentStatus);
    final statusBg = AppColors.statusBackgroundColor(report.currentStatus);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/reports/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image thumbnail ───────────────────────────────────
              if (report.incidentImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    report.incidentImageUrl!
                        .replaceAll('http://minio', ApiConstants.localhost),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          '❌ Image Load Error: $error | URL: ${report.incidentImageUrl!.replaceAll('http://minio', ApiConstants.localhost)}');
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textHint, size: 28),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.textHint, size: 28),
                ),
              const SizedBox(width: 12),

              // ── Text content ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Date
                        Text(
                          _formatDate(report.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

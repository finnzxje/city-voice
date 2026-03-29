import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/report.dart';
import '../../review/viewmodels/staff_workflow_view_model.dart';

/// Dashboard for staff / manager / admin roles.
///
/// Shows all submitted reports with status filter tabs, stats cards,
/// and tappable report cards that navigate to the staff report detail screen.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffWorkflowViewModel>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    final roleName = _roleLabel(authVm.user?.role);

    return Scaffold(
      body: SafeArea(
        child: Consumer<StaffWorkflowViewModel>(
          builder: (context, vm, _) {
            final filtered = _filteredReports(vm.reports);

            return RefreshIndicator(
              onRefresh: () => vm.loadReports(),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────────────
                  SliverToBoxAdapter(
                      child: _buildHeader(theme, authVm, roleName)),

                  // ── Stats ─────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildStatsRow(theme, vm)),

                  // ── Filter Chips ──────────────────────────────────────
                  SliverToBoxAdapter(child: _buildFilterChips(theme)),

                  // ── Section Title ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tất cả báo cáo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${filtered.length} kết quả',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Report List / States ──────────────────────────────
                  if (vm.isLoading && vm.reports.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (vm.errorMessage != null && vm.reports.isEmpty)
                    SliverFillRemaining(child: _buildErrorState(theme, vm))
                  else if (filtered.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(theme))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _StaffReportCard(report: filtered[index]),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtering
  // ═══════════════════════════════════════════════════════════════════════════

  List<Report> _filteredReports(List<Report> reports) {
    if (_statusFilter == 'all') return reports;
    return reports.where((r) => r.currentStatus == _statusFilter).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ThemeData theme, AuthViewModel authVm, String roleName) {
    final name = authVm.user?.fullName ?? 'Nhân viên';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleName,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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

  Widget _buildStatsRow(ThemeData theme, StaffWorkflowViewModel vm) {
    final newCount =
        vm.reports.where((r) => r.currentStatus == 'newly_received').length;
    final inProgressCount =
        vm.reports.where((r) => r.currentStatus == 'in_progress').length;
    final resolvedCount =
        vm.reports.where((r) => r.currentStatus == 'resolved').length;
    final rejectedCount =
        vm.reports.where((r) => r.currentStatus == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatCard(
              label: 'Chờ duyệt',
              count: newCount,
              color: AppColors.statusNew,
              bgColor: AppColors.statusNewBg),
          _StatCard(
              label: 'Đang xử lý',
              count: inProgressCount,
              color: AppColors.statusInProgress,
              bgColor: AppColors.statusInProgressBg),
          _StatCard(
              label: 'Hoàn thành',
              count: resolvedCount,
              color: AppColors.statusResolved,
              bgColor: AppColors.statusResolvedBg),
          _StatCard(
              label: 'Từ chối',
              count: rejectedCount,
              color: AppColors.statusRejected,
              bgColor: AppColors.statusRejectedBg),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = {
      'all': 'Tất cả',
      'newly_received': 'Chờ duyệt',
      'in_progress': 'Đang xử lý',
      'resolved': 'Hoàn thành',
      'rejected': 'Từ chối',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((e) {
            final isSelected = _statusFilter == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _statusFilter = e.key),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Không có báo cáo nào',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            _statusFilter != 'all'
                ? 'Thử đổi bộ lọc để xem báo cáo khác'
                : 'Chưa có báo cáo nào trong hệ thống',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, StaffWorkflowViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(vm.errorMessage!,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => vm.loadReports(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String? role) {
    return switch (role) {
      'admin' => 'ADMIN',
      'manager' => 'QUẢN LÝ',
      'staff' => 'NHÂN VIÊN',
      _ => 'NHÂN VIÊN',
    };
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
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 4,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Staff Report Card ───────────────────────────────────────────────────────

class _StaffReportCard extends StatelessWidget {
  final Report report;

  const _StaffReportCard({required this.report});

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
        onTap: () => context.push('/staff-reports/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title + Status ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(report.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(report.statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Info row ──────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(report.categoryName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (report.priority != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.flag_outlined,
                        size: 14,
                        color: AppColors.priorityColor(report.priority)),
                    const SizedBox(width: 4),
                    Text(report.priorityLabel ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.priorityColor(report.priority),
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // ── Citizen + date ────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(report.citizenName ?? 'Cư dân ẩn danh',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(_formatDate(report.createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textHint, fontSize: 11)),
                ],
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

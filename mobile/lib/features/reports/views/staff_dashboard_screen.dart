import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/report.dart';
import '../../review/viewmodels/staff_workflow_view_model.dart';

/// Dashboard for staff / manager / admin roles.
///
/// Shows all submitted reports with server-side filtering (status, priority,
/// category) and pagination. Tapping a report navigates to the staff detail
/// screen.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<StaffWorkflowViewModel>();
      vm.loadCategories();
      vm.loadReports();
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
            return RefreshIndicator(
              onRefresh: () => vm.loadReports(page: vm.currentPage),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────
                  SliverToBoxAdapter(
                      child: _buildHeader(theme, authVm, roleName)),

                  // ── Filter Section ────────────────────────────
                  SliverToBoxAdapter(child: _buildFilterSection(theme, vm)),

                  // ── Section Title ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách báo cáo',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Trang ${vm.currentPage + 1}/${vm.totalPages}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Report List ───────────────────────────────
                  if (vm.isLoading && vm.reports.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (vm.errorMessage != null && vm.reports.isEmpty)
                    SliverFillRemaining(child: _buildErrorState(theme, vm))
                  else if (vm.reports.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(theme, vm))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: vm.reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _StaffReportCard(report: vm.reports[index]),
                      ),
                    ),

                  // ── Pagination Controls ───────────────────────
                  if (vm.totalPages > 1)
                    SliverToBoxAdapter(child: _buildPaginationBar(theme, vm)),

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
  // Header
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Filter Section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterSection(ThemeData theme, StaffWorkflowViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // ── Row 1: Status + Priority ────────────────────────
          Row(
            children: [
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Trạng thái',
                  value: vm.statusFilter,
                  items: const [
                    DropdownMenuItem(
                        value: 'newly_received', child: Text('Chờ duyệt')),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('Đang xử lý')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Hoàn thành')),
                    DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
                  ],
                  onChanged: (v) => vm.setStatusFilter(v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Ưu tiên',
                  value: vm.priorityFilter,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Thấp')),
                    DropdownMenuItem(
                        value: 'medium', child: Text('Trung bình')),
                    DropdownMenuItem(value: 'high', child: Text('Cao')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Nghiêm trọng')),
                  ],
                  onChanged: (v) => vm.setPriorityFilter(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Row 2: Category + Clear button ──────────────────
          Row(
            children: [
              Expanded(
                child: _FilterDropdown<int>(
                  label: 'Danh mục',
                  value: vm.categoryIdFilter,
                  items: vm.categories
                      .map((c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name,
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          ))
                      .toList(),
                  onChanged: (v) => vm.setCategoryFilter(v),
                ),
              ),
              if (vm.hasActiveFilters) ...[
                const SizedBox(width: 10),
                _ClearFilterButton(onTap: () => vm.clearFilters()),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pagination
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaginationBar(ThemeData theme, StaffWorkflowViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: vm.currentPage > 0,
            onTap: () => vm.goToPage(vm.currentPage - 1),
          ),
          const SizedBox(width: 8),

          // Page numbers
          ...List.generate(
            vm.totalPages > 5 ? 5 : vm.totalPages,
            (index) {
              // Show pages around current page
              int page;
              if (vm.totalPages <= 5) {
                page = index;
              } else if (vm.currentPage <= 2) {
                page = index;
              } else if (vm.currentPage >= vm.totalPages - 3) {
                page = vm.totalPages - 5 + index;
              } else {
                page = vm.currentPage - 2 + index;
              }

              final isActive = page == vm.currentPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => vm.goToPage(page),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isActive ? null : Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${page + 1}',
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Next
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: vm.currentPage < vm.totalPages - 1,
            onTap: () => vm.goToPage(vm.currentPage + 1),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Empty / Error states
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(ThemeData theme, StaffWorkflowViewModel vm) {
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
            vm.hasActiveFilters
                ? 'Thử đổi bộ lọc để xem báo cáo khác'
                : 'Chưa có báo cáo nào trong hệ thống',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
          if (vm.hasActiveFilters) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => vm.clearFilters(),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
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

// ─── Filter Dropdown ─────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          isExpanded: true,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('Tất cả $label',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Clear Filter Button ─────────────────────────────────────────────────────

class _ClearFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.filter_alt_off_rounded,
            size: 20, color: AppColors.error),
      ),
    );
  }
}

// ─── Pagination Button ───────────────────────────────────────────────────────

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: enabled ? AppColors.border : AppColors.divider),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textHint),
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
              // ── Title + Status ─────────────────────────────────
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

              // ── Info row ──────────────────────────────────────
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

              // ── Citizen + date ────────────────────────────────
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

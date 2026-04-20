import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/report.dart';
import '../../review/viewmodels/staff_workflow_view_model.dart';
import 'widgets/staff_filter_widgets.dart';
import 'widgets/staff_report_card.dart';

/// Dashboard for staff / manager / admin roles.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<DateTime, List<Report>> _groupReportsByDate(List<Report> reports) {
    final Map<DateTime, List<Report>> grouped = {};
    for (final report in reports) {
      final date = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(report);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = context.watch<AuthViewModel>();
    final roleName = _roleLabel(authVm.user?.role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<StaffWorkflowViewModel>(
          builder: (context, vm, _) {
            var filteredReports = vm.reports;

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              filteredReports = filteredReports
                  .where((r) =>
                      r.title.toLowerCase().contains(query) ||
                      (r.citizenName?.toLowerCase().contains(query) ?? false))
                  .toList();
            }

            if (_selectedDate != null) {
              filteredReports = filteredReports
                  .where((r) =>
                      r.createdAt.year == _selectedDate!.year &&
                      r.createdAt.month == _selectedDate!.month &&
                      r.createdAt.day == _selectedDate!.day)
                  .toList();
            }

            final groupedReports = _groupReportsByDate(filteredReports);
            final sortedDates = groupedReports.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            final isAnyFilterActive = vm.hasActiveFilters ||
                _searchQuery.isNotEmpty ||
                _selectedDate != null;

            return RefreshIndicator(
              onRefresh: () => vm.loadReports(page: vm.currentPage),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: _buildHeader(theme, authVm, roleName)),
                  SliverToBoxAdapter(
                      child: _buildFilterSection(theme, vm, isAnyFilterActive)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách báo cáo',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Trang ${vm.currentPage + 1}/${vm.totalPages > 0 ? vm.totalPages : 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Report List ──
                  if (vm.isLoading && vm.reports.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (vm.errorMessage != null && vm.reports.isEmpty)
                    SliverFillRemaining(child: _buildErrorState(theme, vm))
                  else if (filteredReports.isEmpty)
                    SliverFillRemaining(
                        child: _buildEmptyState(theme, vm, isAnyFilterActive))
                  else
                    SliverList.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];
                        final reportsForDate = groupedReports[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(date),
                            SizedBox(
                              height: 330,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: reportsForDate.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, cardIndex) {
                                  return StaffHorizontalReportCard(
                                    report: reportsForDate[cardIndex],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

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
  // Filter Section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterSection(
      ThemeData theme, StaffWorkflowViewModel vm, bool isAnyFilterActive) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              if (isAnyFilterActive) ...[
                const SizedBox(width: 10),
                ClearFilterButton(onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedDate = null;
                  });
                  vm.clearFilters();
                }),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilterDropdown<String>(
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
                child: FilterDropdown<String>(
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
          Row(
            children: [
              Expanded(
                child: FilterDropdown<int>(
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
              const SizedBox(width: 10),
              Expanded(child: _buildDatePickerButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _searchQuery.isNotEmpty
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchQuery.isNotEmpty ? AppColors.primary : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên báo cáo...',
          hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDate) {
          setState(() => _selectedDate = picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _selectedDate != null
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedDate != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : 'Chọn ngày',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDate != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontWeight: _selectedDate != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                  fontStyle: _selectedDate != null
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today_rounded,
                size: 18,
                color: _selectedDate != null
                    ? AppColors.primary
                    : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Date Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    Color bgColor;

    if (date == today) {
      label =
          'HÔM NAY, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      bgColor = const Color(0xFF0044CC);
    } else if (date == yesterday) {
      label =
          'HÔM QUA, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      bgColor = const Color(0xFF6B7280);
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      bgColor = const Color(0xFF6B7280);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
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
                    color: AppColors.accent.withOpacity(0.15),
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
  // Pagination
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaginationBar(ThemeData theme, StaffWorkflowViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: vm.currentPage > 0,
            onTap: () => vm.goToPage(vm.currentPage - 1),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            vm.totalPages > 5 ? 5 : vm.totalPages,
            (index) {
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
          PaginationButton(
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

  Widget _buildEmptyState(
      ThemeData theme, StaffWorkflowViewModel vm, bool isAnyFilterActive) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Không có báo cáo nào',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            isAnyFilterActive
                ? 'Thử đổi bộ lọc để xem báo cáo khác'
                : 'Chưa có báo cáo nào trong hệ thống',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
          if (isAnyFilterActive) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedDate = null;
                });
                vm.clearFilters();
              },
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

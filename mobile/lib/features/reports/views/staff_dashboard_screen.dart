import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/incident_category.dart';
import '../../reports/models/report.dart';
import '../../review/viewmodels/staff_workflow_view_model.dart';
import 'staff_dashboard/staff_dashboard_presenter.dart';
import 'widgets/staff_filter_widgets.dart';
import 'widgets/staff_report_card.dart';

typedef _StaffDashboardViewState = ({
  List<Report> reports,
  bool isLoading,
  String? errorMessage,
  int currentPage,
  int totalPages,
  bool hasActiveFilters,
  String? statusFilter,
  String? priorityFilter,
  int? categoryIdFilter,
  List<IncidentCategory> categories,
});

/// Dashboard for staff / manager / admin roles.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchInput = '';
  StaffDashboardLocalFilters _localFilters = const StaffDashboardLocalFilters();
  StaffDashboardPresenter? _presenterCache;
  Object? _presenterReportsIdentity;
  StaffDashboardLocalFilters? _presenterFilters;
  bool? _presenterHasRemoteFilters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<StaffWorkflowViewModel>();
      viewModel.loadCategories();
      viewModel.loadReports();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchQuery(String value) {
    if (value != _searchInput) {
      setState(() {
        _searchInput = value;
      });
    }

    _searchDebounce?.cancel();
    if (value == _localFilters.searchQuery) {
      return;
    }

    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _localFilters = _localFilters.copyWith(searchQuery: value);
      });
    });
  }

  StaffDashboardPresenter _presenterFor({
    required List<Report> reports,
    required bool hasRemoteFilters,
  }) {
    final cachedPresenter = _presenterCache;

    if (cachedPresenter != null &&
        identical(_presenterReportsIdentity, reports) &&
        _presenterFilters == _localFilters &&
        _presenterHasRemoteFilters == hasRemoteFilters) {
      return cachedPresenter;
    }

    final presenter = StaffDashboardPresenter(
      reports: reports,
      localFilters: _localFilters,
      hasRemoteFilters: hasRemoteFilters,
    );

    _presenterCache = presenter;
    _presenterReportsIdentity = reports;
    _presenterFilters = _localFilters;
    _presenterHasRemoteFilters = hasRemoteFilters;

    return presenter;
  }

  void _setSelectedDate(DateTime? value) {
    setState(() {
      _localFilters = _localFilters.copyWith(selectedDate: value);
    });
  }

  void _clearLocalFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _searchInput = '';
      _localFilters = const StaffDashboardLocalFilters();
    });
  }

  void _clearAllFilters(StaffWorkflowViewModel viewModel) {
    _clearLocalFilters();
    viewModel.clearFilters();
  }

  Future<void> _pickDate() async {
    final selectedDate = _localFilters.selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
    if (picked == null || picked == selectedDate) {
      return;
    }

    _setSelectedDate(picked);
  }

  int _pageNumberForIndex(int index, int currentPage, int totalPages) {
    if (totalPages <= 5 || currentPage <= 2) {
      return index;
    }

    if (currentPage >= totalPages - 3) {
      return totalPages - 5 + index;
    }

    return currentPage - 2 + index;
  }

  Color _dateHeaderBackgroundColor(StaffDashboardDateHeader header) {
    if (header.isToday) {
      return const Color(0xFF0044CC);
    }

    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.read<StaffWorkflowViewModel>();
    final staffName = context.select<AuthViewModel, String>(
      (vm) => vm.user?.fullName ?? 'Nhân viên',
    );
    final roleName = context.select<AuthViewModel, String>(
      (vm) => (vm.user?.role ?? UserRole.staff).staffDashboardBadgeLabel,
    );
    final viewState =
        context.select<StaffWorkflowViewModel, _StaffDashboardViewState>(
      (vm) => (
        reports: vm.reports,
        isLoading: vm.isLoading,
        errorMessage: vm.errorMessage,
        currentPage: vm.currentPage,
        totalPages: vm.totalPages,
        hasActiveFilters: vm.hasActiveFilters,
        statusFilter: vm.statusFilter,
        priorityFilter: vm.priorityFilter,
        categoryIdFilter: vm.categoryIdFilter,
        categories: vm.categories,
      ),
    );
    final presenter = _presenterFor(
      reports: viewState.reports,
      hasRemoteFilters: viewState.hasActiveFilters,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.loadReports(page: viewState.currentPage),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(theme, staffName, roleName),
              ),
              SliverToBoxAdapter(
                child: _buildFilterSection(
                  presenter: presenter,
                  viewModel: viewModel,
                  statusFilter: viewState.statusFilter,
                  priorityFilter: viewState.priorityFilter,
                  categoryIdFilter: viewState.categoryIdFilter,
                  categories: viewState.categories,
                ),
              ),
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
                        'Trang ${viewState.currentPage + 1}/${viewState.totalPages > 0 ? viewState.totalPages : 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (viewState.isLoading && viewState.reports.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (viewState.errorMessage != null &&
                  viewState.reports.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(
                    theme,
                    viewState.errorMessage!,
                    onRetry: viewModel.loadReports,
                  ),
                )
              else if (presenter.filteredReports.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(theme, viewModel, presenter),
                )
              else
                SliverList.builder(
                  itemCount: presenter.dateGroups.length,
                  itemBuilder: (context, index) {
                    final dateGroup = presenter.dateGroups[index];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(dateGroup.header),
                        SizedBox(
                          height: 330,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: dateGroup.reports.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, cardIndex) {
                              return StaffHorizontalReportCard(
                                key: ValueKey(
                                  dateGroup.reports[cardIndex].id,
                                ),
                                report: dateGroup.reports[cardIndex],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              if (viewState.totalPages > 1)
                SliverToBoxAdapter(
                  child: _buildPaginationBar(
                    viewModel: viewModel,
                    currentPage: viewState.currentPage,
                    totalPages: viewState.totalPages,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required StaffWorkflowViewModel viewModel,
    required StaffDashboardPresenter presenter,
    required String? statusFilter,
    required String? priorityFilter,
    required int? categoryIdFilter,
    required List<IncidentCategory> categories,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              if (presenter.isAnyFilterActive) ...[
                const SizedBox(width: 10),
                ClearFilterButton(
                  onTap: () => _clearAllFilters(viewModel),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilterDropdown<String>(
                  label: 'Trạng thái',
                  value: statusFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'newly_received',
                      child: Text('Chờ duyệt'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Đang xử lý'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Từ chối'),
                    ),
                  ],
                  onChanged: viewModel.setStatusFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilterDropdown<String>(
                  label: 'Ưu tiên',
                  value: priorityFilter,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Thấp')),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(value: 'high', child: Text('Cao')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Nghiêm trọng'),
                    ),
                  ],
                  onChanged: viewModel.setPriorityFilter,
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
                  value: categoryIdFilter,
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: viewModel.setCategoryFilter,
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
    final searchQuery = _searchInput;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: searchQuery.isNotEmpty
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: searchQuery.isNotEmpty ? AppColors.primary : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _setSearchQuery,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên báo cáo...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _clearLocalFilters,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    final selectedDate = _localFilters.selectedDate;

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selectedDate != null
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(selectedDate)
                    : 'Chọn ngày',
                style: TextStyle(
                  fontSize: 13,
                  color: selectedDate != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontWeight: selectedDate != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                  fontStyle: selectedDate != null
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: selectedDate != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(StaffDashboardDateHeader header) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _dateHeaderBackgroundColor(header),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              header.label,
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

  Widget _buildHeader(
    ThemeData theme,
    String staffName,
    String roleName,
  ) {
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
                  staffName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final authViewModel = context.read<AuthViewModel>();
              final router = GoRouter.of(context);
              await authViewModel.logout();
              router.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar({
    required StaffWorkflowViewModel viewModel,
    required int currentPage,
    required int totalPages,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 0,
            onTap: () => viewModel.goToPage(currentPage - 1),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            totalPages > 5 ? 5 : totalPages,
            (index) {
              final page = _pageNumberForIndex(
                index,
                currentPage,
                totalPages,
              );
              final isActive = page == currentPage;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => viewModel.goToPage(page),
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
            enabled: currentPage < totalPages - 1,
            onTap: () => viewModel.goToPage(currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    StaffWorkflowViewModel viewModel,
    StaffDashboardPresenter presenter,
  ) {
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
            'Không có báo cáo nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            presenter.isAnyFilterActive
                ? 'Thử đổi bộ lọc để xem báo cáo khác'
                : 'Chưa có báo cáo nào trong hệ thống',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          if (presenter.isAnyFilterActive) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _clearAllFilters(viewModel),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    String errorMessage, {
    required Future<void> Function() onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

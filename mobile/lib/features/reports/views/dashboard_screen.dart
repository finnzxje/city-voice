import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../notifications/viewmodels/notification_view_model.dart';
import '../viewmodels/report_view_model.dart';
import 'widgets/status_stat_card.dart';
import 'widgets/timeline_report_card.dart';

/// Main dashboard screen for citizens.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadDashboard();
      context.read<NotificationViewModel>().initBadgeOnly();
    });
  }

  void _onStatusFilterTapped(String status) {
    setState(() {
      _selectedStatus = _selectedStatus == status ? null : status;
    });
  }

  Future<void> _showCategoryFilterBottomSheet(ReportViewModel vm) async {
    if (vm.categories.isEmpty) {
      await vm.loadCategories();
      if (!mounted) {
        return;
      }
    }

    final uniqueCategories = vm.categories.map((r) => r.name).toSet().toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Chọn danh mục lọc',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              if (uniqueCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Không có danh mục nào.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueCategories.length,
                    itemBuilder: (context, index) {
                      final category = uniqueCategories[index];
                      final isSelected = _selectedCategory == category;
                      return ListTile(
                        title: Text(
                          category,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userFullName = context.select<AuthViewModel, String>(
      (vm) => vm.user?.fullName ?? 'Cư dân',
    );
    final unreadCount = context.select<NotificationViewModel, int>(
      (vm) => vm.unreadCount,
    );
    final dashboardSnapshot =
        context.select<ReportViewModel, ReportDashboardSnapshot>(
      (vm) => vm.dashboardSnapshot(
        selectedStatus: _selectedStatus,
        selectedCategory: _selectedCategory,
      ),
    );
    final isLoading = context.select<ReportViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final errorMessage = context.select<ReportViewModel, String?>(
      (vm) => vm.errorMessage,
    );
    final reportViewModel = context.read<ReportViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final notificationViewModel = context.read<NotificationViewModel>();
            await reportViewModel.refreshReports();
            await notificationViewModel.loadUnreadCount();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(
                  theme,
                  userFullName: userFullName,
                  unreadCount: unreadCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildStatsGrid(dashboardSnapshot),
              ),
              SliverToBoxAdapter(
                child: _buildListHeader(
                  theme,
                  dashboardSnapshot.displayedCount,
                  reportViewModel,
                ),
              ),
              if (isLoading && dashboardSnapshot.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (errorMessage != null && dashboardSnapshot.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(
                    theme,
                    errorMessage,
                    reportViewModel.loadDashboard,
                  ),
                )
              else if (dashboardSnapshot.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(theme))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: dashboardSnapshot.items.length,
                    itemBuilder: (context, index) {
                      final item = dashboardSnapshot.items[index];
                      return TimelineReportCard(
                        key: ValueKey(item.report.id),
                        report: item.report,
                        showDate: item.showDate,
                        isLast: item.isLast,
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reports/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.note_alt_outlined, size: 26),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
    ThemeData theme, {
    required String userFullName,
    required int unreadCount,
  }) {
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
                  userFullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
                iconSize: 28,
                color: AppColors.textPrimary,
              ),
              if (unreadCount > 0)
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
                      unreadCount > 9 ? '9+' : '$unreadCount',
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
              context.read<NotificationViewModel>().stopPolling();
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
  // Stats Grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(ReportDashboardSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatusStatCard(
                  label: 'Mới tiếp\nnhận',
                  count: snapshot.newlyReceivedCount,
                  icon: Icons.note_add_rounded,
                  iconColor: const Color(0xFF0044CC),
                  bgColor: const Color(0xFFEBF0FF),
                  textColor: _selectedStatus == 'newly_received'
                      ? const Color(0xFF0044CC)
                      : Colors.black,
                  isSelected: _selectedStatus == 'newly_received',
                  onTap: () => _onStatusFilterTapped('newly_received'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatusStatCard(
                  label: 'Đang\nxử lý',
                  count: snapshot.inProgressCount,
                  icon: Icons.assignment_late_rounded,
                  iconColor: const Color(0xFFCC4400),
                  bgColor: const Color(0xFFFFF0E5),
                  textColor: _selectedStatus == 'in_progress'
                      ? const Color(0xFFCC4400)
                      : Colors.black,
                  isSelected: _selectedStatus == 'in_progress',
                  onTap: () => _onStatusFilterTapped('in_progress'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatusStatCard(
                  label: 'Hoàn\nthành',
                  count: snapshot.resolvedCount,
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF008033),
                  bgColor: const Color(0xFFE5F7ED),
                  textColor: _selectedStatus == 'resolved'
                      ? const Color(0xFF008033)
                      : Colors.black,
                  isSelected: _selectedStatus == 'resolved',
                  onTap: () => _onStatusFilterTapped('resolved'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatusStatCard(
                  label: 'Bị từ\nchối',
                  count: snapshot.rejectedCount,
                  icon: Icons.cancel_rounded,
                  iconColor: const Color(0xFFCC0000),
                  bgColor: const Color(0xFFFFE5E5),
                  textColor: _selectedStatus == 'rejected'
                      ? const Color(0xFFCC0000)
                      : Colors.black,
                  isSelected: _selectedStatus == 'rejected',
                  onTap: () => _onStatusFilterTapped('rejected'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // List Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildListHeader(
      ThemeData theme, int displayedCount, ReportViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Danh sách báo cáo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$displayedCount',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showCategoryFilterBottomSheet(vm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_rounded,
                          size: 16, color: Color(0xFF374151)),
                      const SizedBox(width: 6),
                      Text(
                        'Lọc',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = null),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCategory!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Empty / Error states
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            (_selectedStatus != null || _selectedCategory != null)
                ? 'Không có báo cáo nào phù hợp với bộ lọc'
                : 'Chưa có báo cáo nào',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          if (_selectedStatus == null && _selectedCategory == null)
            Text(
              'Nhấn nút "Báo cáo mới" để gửi sự cố đầu tiên',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textHint),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    String errorMessage,
    Future<void> Function() onRetry,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
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

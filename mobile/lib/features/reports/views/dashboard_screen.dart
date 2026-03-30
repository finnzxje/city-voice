import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/utils.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../notifications/viewmodels/notification_view_model.dart';
import '../models/report.dart';
import '../viewmodels/report_view_model.dart';

/// Main dashboard screen for citizens.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State variables for filtering
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadDashboard();
      context.read<NotificationViewModel>().init();
    });
  }

  // Toggle status filter selection (from the 4 top cards)
  void _onStatusFilterTapped(String status) {
    setState(() {
      if (_selectedStatus == status) {
        _selectedStatus = null; // Unselect
      } else {
        _selectedStatus = status; // Select new filter
      }
    });
  }

  // Show bottom sheet to select a category
  void _showCategoryFilterBottomSheet(
      BuildContext context, ReportViewModel vm) {
    final uniqueCategories = vm.categories.map((r) => r.name).toSet().toList();
    uniqueCategories.sort();

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
              // Bottom sheet handle
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
                          setState(() {
                            _selectedCategory = category;
                          });
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
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<ReportViewModel>(
          builder: (context, vm, _) {
            // Apply local filtering based on selected status AND selected category
            var displayedReports = vm.reports;

            if (_selectedStatus != null) {
              displayedReports = displayedReports
                  .where((r) => r.currentStatus == _selectedStatus)
                  .toList();
            }

            if (_selectedCategory != null) {
              displayedReports = displayedReports
                  .where((r) => r.categoryName == _selectedCategory)
                  .toList();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final notifVm = context.read<NotificationViewModel>();
                await vm.refreshReports();
                await notifVm.refresh(showLoading: false);
              },
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── Header ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(theme, authVm, vm),
                  ),

                  // ── Stats Cards (status filters) ──────────────
                  SliverToBoxAdapter(
                    child: _buildStatsGrid(vm),
                  ),

                  // ── List Title, Count Badge & Category Filter ────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Title, Count Badge, and Filter Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Title and Count Badge
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Danh sách báo cáo',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Total Count Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${displayedReports.length}',
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

                              // Open Category Filter Button
                              GestureDetector(
                                onTap: () =>
                                    _showCategoryFilterBottomSheet(context, vm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
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
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
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

                          // Bottom Row: Active Category Filter Chip
                          if (_selectedCategory != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  // Wrap content
                                  children: [
                                    Text(
                                      _selectedCategory!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                    ),
                  ),

                  // ── Timeline List ────────────────────────────────────
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
                  else if (displayedReports.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(theme),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: displayedReports.length,
                        itemBuilder: (context, index) {
                          final report = displayedReports[index];
                          bool showDate = true;

                          // Logic to group by date
                          if (index > 0) {
                            final prevReport = displayedReports[index - 1];
                            if (report.createdAt.day ==
                                    prevReport.createdAt.day &&
                                report.createdAt.month ==
                                    prevReport.createdAt.month &&
                                report.createdAt.year ==
                                    prevReport.createdAt.year) {
                              showDate = false;
                            }
                          }

                          return _TimelineReportCard(
                            report: report,
                            showDate: showDate,
                            isLast: index == displayedReports.length - 1,
                          );
                        },
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

      // ── FAB ──────────────────────────────────────────────────────────
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

          // Notification bell with badge (from NotificationViewModel)
          Consumer<NotificationViewModel>(
            builder: (ctx, notifVm, _) => Stack(
              children: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                  iconSize: 28,
                  color: AppColors.textPrimary,
                ),
                if (notifVm.unreadCount > 0)
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
                        notifVm.unreadCount > 9
                            ? '9+'
                            : '${notifVm.unreadCount}',
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

  // 4 Status Cards Grid
  Widget _buildStatsGrid(ReportViewModel vm) {
    final newCount =
        vm.reports.where((r) => r.currentStatus == 'newly_received').length;
    final inProgressCount =
        vm.reports.where((r) => r.currentStatus == 'in_progress').length;
    final resolvedCount =
        vm.reports.where((r) => r.currentStatus == 'resolved').length;
    final rejectedCount =
        vm.reports.where((r) => r.currentStatus == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NewStatCard(
                  label: 'Mới tiếp\nnhận',
                  count: newCount,
                  icon: Icons.note_add_rounded,
                  iconColor: const Color(0xFF0044CC),
                  bgColor: const Color(0xFFEBF0FF),
                  textColor: (_selectedStatus == 'newly_received')
                      ? Color(0xFF0044CC)
                      : Colors.black,
                  isSelected: _selectedStatus == 'newly_received',
                  onTap: () => _onStatusFilterTapped('newly_received'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NewStatCard(
                  label: 'Đang\nxử lý',
                  count: inProgressCount,
                  icon: Icons.assignment_late_rounded,
                  iconColor: const Color(0xFFCC4400),
                  bgColor: const Color(0xFFFFF0E5),
                  textColor: (_selectedStatus == 'in_progress')
                      ? Color(0xFFCC4400)
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
                child: _NewStatCard(
                  label: 'Hoàn\nthành',
                  count: resolvedCount,
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF008033),
                  bgColor: const Color(0xFFE5F7ED),
                  textColor: (_selectedStatus == 'resolved')
                      ? Color(0xFF008033)
                      : Colors.black,
                  isSelected: _selectedStatus == 'resolved',
                  onTap: () => _onStatusFilterTapped('resolved'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NewStatCard(
                  label: 'Bị từ\nchối',
                  count: rejectedCount,
                  icon: Icons.cancel_rounded,
                  iconColor: const Color(0xFFCC0000),
                  bgColor: const Color(0xFFFFE5E5),
                  textColor: (_selectedStatus == 'rejected')
                      ? Color(0xFFCC0000)
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            (_selectedStatus != null || _selectedCategory != null)
                ? 'Không có báo cáo nào phù hợp với bộ lọc'
                : 'Chưa có báo cáo nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (_selectedStatus == null && _selectedCategory == null)
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

// ─── Stat Card  ──────────────────────────────────────────────────

class _NewStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _NewStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          // Add border if selected to indicate active filter
          border: Border.all(
            color: isSelected ? iconColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            Text(
              count.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Report Card ────────────────────────────────────────────────────

class _TimelineReportCard extends StatelessWidget {
  final Report report;
  final bool showDate;
  final bool isLast;

  const _TimelineReportCard({
    required this.report,
    required this.showDate,
    required this.isLast,
  });

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "HÔM NAY";
    }
    // Format: 12 THÁNG 10, 2023
    return "${date.day} THÁNG ${date.month}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(report.currentStatus);
    final statusBg = AppColors.statusBackgroundColor(report.currentStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Timeline Column ──
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vertical dashed line
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedLinePainter(
                      color: Colors.blue.withOpacity(0.2),
                      isLast: isLast,
                    ),
                  ),
                ),
                // Circle indicator (Only show for new dates)
                if (showDate)
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                        color: const Color(0xFFF8F9FA),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right Card Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) ...[
                  Text(
                    _formatDateHeader(report.createdAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Main Content Card
                GestureDetector(
                  onTap: () => context.push('/reports/${report.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: report.incidentImageUrl != null
                                  ? Image.network(
                                      Utils.getSafeUrl(report.incidentImageUrl),
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholderImage(),
                                    )
                                  : _buildPlaceholderImage(),
                            ),
                            // Status Badge floating on image
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBg.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        switch (report.currentStatus) {
                                          'newly_received' =>
                                            Icons.star_border_outlined,
                                          'in_progress' =>
                                            Icons.access_time_outlined,
                                          'resolved' =>
                                            Icons.check_circle_outline_outlined,
                                          'rejected' => Icons.cancel_outlined,
                                          _ => Icons.fiber_new_rounded,
                                        },
                                        size: 12,
                                        color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      report.statusLabel.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Text Info below image
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label_rounded,
                                      size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      report.categoryName.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.description ??
                                    'Không có mô tả chi tiết.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 140,
      color: const Color(0xFF4A7C75),
      child: const Center(
        child: Text(
          'INCIDENT',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter for Timeline Dashed Line ─────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final bool isLast;

  _DashedLinePainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 16;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    // If it's the last item, don't draw the line to the very bottom
    final endY = isLast ? size.height - 40 : size.height;

    while (startY < endY) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

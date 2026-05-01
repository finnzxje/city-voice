import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/services/category_service.dart';
import '../viewmodels/analytics_view_model.dart';
import 'widgets/analytics_filter_sheet.dart';
import 'widgets/charts_section.dart';
import 'widgets/export_section.dart';
import 'widgets/heatmap_section.dart';
import 'widgets/scorecards_row.dart';
import 'widgets/status_breakdown.dart';

/// Full-featured analytics dashboard for managers and admins.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.select<AuthViewModel, UserRole?>(
      (vm) => vm.user?.role,
    );
    final hasActiveFilters = context.select<AnalyticsViewModel, bool>(
      (vm) => vm.activeFilter.hasActiveFilters,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Báo cáo & Phân tích'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: userRole == UserRole.manager
            ? IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  final authVm = context.read<AuthViewModel>();
                  await authVm.logout();
                  if (context.mounted) context.go('/login');
                },
              )
            : null,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                tooltip: 'Bộ lọc',
                onPressed: () => _showFilterSheet(context),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalyticsViewModel>().loadDashboard(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScorecardsRow(),
              SizedBox(height: 20),
              StatusBreakdown(),
              SizedBox(height: 24),
              ChartsSection(),
              SizedBox(height: 24),
              HeatmapSection(),
              SizedBox(height: 24),
              ExportSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final vm = context.read<AnalyticsViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: AnalyticsFilterSheet(
          currentFilter: vm.activeFilter,
          categoryService: context.read<CategoryService>(),
        ),
      ),
    );
  }
}

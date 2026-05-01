import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_category_list_screen.dart';
import '../../features/admin/views/admin_dashboard_screen.dart';
import '../../features/admin/views/admin_user_list_screen.dart';
import '../../features/analytics/views/analytics_dashboard_screen.dart';
import '../../features/auth/viewmodels/auth_view_model.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/verify_email_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/reports/views/dashboard_screen.dart';
import '../../features/reports/views/report_detail_screen.dart';
import '../../features/reports/views/staff_dashboard_screen.dart';
import '../../features/reports/views/submit_report_screen.dart';
import '../../features/review/views/staff_report_detail_screen.dart';
import '../auth/user_role.dart';
import 'app_routes.dart';
import '../storage/secure_storage_helper.dart';

class AppRouter {
  final SecureStorageHelper _storage;
  final AuthViewModel _authViewModel;

  /// Global navigator key for overlay access (in-app push notifications).
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppRouter({
    required SecureStorageHelper storage,
    required AuthViewModel authViewModel,
  })  : _storage = storage,
        _authViewModel = authViewModel;

  late final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: Listenable.merge([_authViewModel, _storage]),
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const _AppSplashScreen(),
      ),

      // ── Auth Routes ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.verifyEmail,
        name: AppRouteNames.verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // ── Citizen routes ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutePaths.dashboard,
        name: AppRouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.submitReport,
        name: AppRouteNames.submitReport,
        builder: (context, state) => const SubmitReportScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.reportDetailPattern,
        name: AppRouteNames.reportDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: AppRoutePaths.notifications,
        name: AppRouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ── Staff / Manager routes ────────────────────────────────────────
      GoRoute(
        path: AppRoutePaths.staffDashboard,
        name: AppRouteNames.staffDashboard,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.staffReportDetailPattern,
        name: AppRouteNames.staffReportDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StaffReportDetailScreen(reportId: id);
        },
      ),

      // ── Admin routes ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutePaths.adminDashboard,
        name: AppRouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.adminUsers,
        name: AppRouteNames.adminUsers,
        builder: (context, state) => const AdminUserListScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.adminCategories,
        name: AppRouteNames.adminCategories,
        builder: (context, state) => const AdminCategoryListScreen(),
      ),

      // ── Analytics route (manager + admin) ──────────────────────────────
      GoRoute(
        path: AppRoutePaths.analytics,
        name: AppRouteNames.analytics,
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Global redirect — auth + role guard
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String?> _globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final authVm = _authViewModel;
    final currentPath = state.matchedLocation;

    if (authVm.isRestoringSession) {
      return currentPath == AppRoutePaths.splash ? null : AppRoutePaths.splash;
    }

    final hasToken = await _storage.hasTokens();
    final homepage = _homepageForRole(authVm);

    if (currentPath == AppRoutePaths.splash) {
      return hasToken ? homepage : AppRoutePaths.login;
    }

    final isOnPublicPage = AppRoutePaths.publicPaths.contains(currentPath);

    // Not authenticated → go to login
    if (!hasToken && !isOnPublicPage) {
      return AppRoutePaths.login;
    }

    // Authenticated → redirect away from auth pages based on role
    if (hasToken && isOnPublicPage) {
      return homepage;
    }

    final role = authVm.user?.role;
    final isAdmin = role == UserRole.admin;
    final isStaffOrManager = role?.isStaffOrManager ?? false;
    final isCitizen = role?.isCitizen ?? false;

    // ── Admin route guard ────────────────────────────────────────────────
    final isAdminRoute = AppRoutePaths.isAdminRoute(currentPath);
    if (isAdminRoute && !isAdmin) {
      return homepage;
    }

    // ── Role-based cross-routing guards ──────────────────────────────────
    final isCitizenOnlyRoute = AppRoutePaths.isCitizenOnlyRoute(currentPath);
    final isStaffRoute = AppRoutePaths.isStaffRoute(currentPath);

    // Admin trying to access citizen-only routes → admin dashboard
    if (isAdmin && isCitizenOnlyRoute) {
      return AppRoutePaths.adminDashboard;
    }

    // Staff/manager trying to access citizen-only routes
    if (isStaffOrManager && isCitizenOnlyRoute) {
      return homepage;
    }

    // Citizen trying to access staff/admin routes
    if (isCitizen && (isStaffRoute || isAdminRoute)) {
      return AppRoutePaths.dashboard;
    }

    // ── Analytics route guard: only manager + admin ─────────────────────
    final isAnalyticsRoute = currentPath == AppRoutePaths.analytics;
    if (isAnalyticsRoute && !(role?.canAccessAnalytics ?? false)) {
      return homepage;
    }

    return null;
  }

  /// Returns the correct homepage path based on the user's role.
  String _homepageForRole(AuthViewModel authVm) {
    return authVm.user?.homeRoute ?? UserRole.citizen.homeRoute;
  }
}

class _AppSplashScreen extends StatelessWidget {
  const _AppSplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

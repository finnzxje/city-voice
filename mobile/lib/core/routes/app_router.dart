import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage_helper.dart';
import '../../features/auth/viewmodels/auth_view_model.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/verify_email_screen.dart';
import '../../features/reports/views/dashboard_screen.dart';
import '../../features/reports/views/staff_dashboard_screen.dart';
import '../../features/reports/views/submit_report_screen.dart';
import '../../features/reports/views/report_detail_screen.dart';
import '../../features/review/views/staff_report_detail_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';

/// Declarative routing configuration for CityVoice.
///
/// Uses [GoRouter] with a redirect guard that sends unauthenticated
/// users to the login screen and routes authenticated users to the
/// appropriate dashboard based on their role:
///   - citizen → `/dashboard`
///   - staff/manager/admin → `/staff-dashboard`
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
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([_authViewModel, _storage]),
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _AppSplashScreen(),
      ),

      // ── Auth Routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // ── Citizen routes ────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/reports/new',
        name: 'submit-report',
        builder: (context, state) => const SubmitReportScreen(),
      ),
      GoRoute(
        path: '/reports/:id',
        name: 'report-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ── Staff / Manager / Admin routes ─────────────────────────────
      GoRoute(
        path: '/staff-dashboard',
        name: 'staff-dashboard',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff-reports/:id',
        name: 'staff-report-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StaffReportDetailScreen(reportId: id);
        },
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
    final hasToken = await _storage.hasTokens();
    final currentPath = state.matchedLocation;
    final homepage = _homepageForRole(authVm);

    if (authVm.isRestoringSession) {
      return currentPath == '/splash' ? null : '/splash';
    }

    if (currentPath == '/splash') {
      return hasToken ? homepage : '/login';
    }

    const publicPaths = {'/login', '/register', '/verify-email', '/splash'};
    final isOnPublicPage = publicPaths.contains(currentPath);

    // Not authenticated → go to login
    if (!hasToken && !isOnPublicPage) {
      return '/login';
    }

    // Authenticated → redirect away from auth pages based on role
    if (hasToken && isOnPublicPage) {
      return homepage;
    }

    final role = authVm.user?.role;
    final isInternal = role == 'staff' || role == 'manager' || role == 'admin';
    final isCitizenOnlyRoute =
        currentPath == '/dashboard' || currentPath == '/reports/new';
    final isStaffOnlyRoute = currentPath == '/staff-dashboard' ||
        currentPath.startsWith('/staff-reports');

    if (isInternal && isCitizenOnlyRoute) {
      return '/staff-dashboard';
    }

    if (!isInternal && isStaffOnlyRoute) {
      return '/dashboard';
    }

    return null;
  }

  /// Returns the correct homepage path based on the user's role.
  String _homepageForRole(AuthViewModel authVm) {
    final role = authVm.user?.role;
    if (role == 'staff' || role == 'manager' || role == 'admin') {
      return '/staff-dashboard';
    }
    return '/dashboard';
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

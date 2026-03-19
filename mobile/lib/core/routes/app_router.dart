import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../storage/secure_storage_helper.dart';
import '../../features/auth/viewmodels/auth_view_model.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/verify_email_screen.dart';
import '../../features/reports/views/dashboard_screen.dart';
import '../../features/reports/views/staff_dashboard_screen.dart';
import '../../features/reports/views/submit_report_screen.dart';
import '../../features/reports/views/report_detail_screen.dart';

/// Declarative routing configuration for CityVoice.
///
/// Uses [GoRouter] with a redirect guard that sends unauthenticated
/// users to the login screen and routes authenticated users to the
/// appropriate dashboard based on their role:
///   - citizen → `/dashboard`
///   - staff/manager/admin → `/staff-dashboard`
class AppRouter {
  final SecureStorageHelper _storage;

  AppRouter({required SecureStorageHelper storage}) : _storage = storage;

  late final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    routes: [
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

      // ── Staff / Manager / Admin routes ─────────────────────────────
      GoRoute(
        path: '/staff-dashboard',
        name: 'staff-dashboard',
        builder: (context, state) => const StaffDashboardScreen(),
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
    // Capture role-based homepage BEFORE the async gap.
    final homepage = _homepageForRole(context);
    final hasToken = await _storage.hasTokens();
    final currentPath = state.matchedLocation;

    const publicPaths = {'/login', '/register', '/verify-email'};
    final isOnPublicPage = publicPaths.contains(currentPath);

    // Not authenticated → go to login
    if (!hasToken && !isOnPublicPage) {
      return '/login';
    }

    // Authenticated → redirect away from auth pages based on role
    if (hasToken && isOnPublicPage) {
      return homepage;
    }

    return null;
  }

  /// Returns the correct homepage path based on the user's role.
  String _homepageForRole(BuildContext context) {
    try {
      final authVm = context.read<AuthViewModel>();
      final role = authVm.user?.role;
      if (role == 'staff' || role == 'manager' || role == 'admin') {
        return '/staff-dashboard';
      }
    } catch (_) {}
    return '/dashboard';
  }
}

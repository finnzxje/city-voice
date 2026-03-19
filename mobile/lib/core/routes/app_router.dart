import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage_helper.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/verify_email_screen.dart';

/// Declarative routing configuration for CityVoice.
///
/// Uses [GoRouter] with a redirect guard that sends unauthenticated
/// users to the login screen and prevents authenticated users from
/// visiting auth pages.
///
/// Route tree:
/// ```
/// /login                ← Citizen/Staff login (Password + OTP)
/// /register             ← Citizen registration
/// /verify-email?email=  ← Email OTP verification
/// /dashboard            ← Protected — citizen home
/// /reports/new          ← Protected — submit report
/// /reports/:id          ← Protected — report detail
/// ```
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

      // ── Protected Routes ─────────────────
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const _PlaceholderPage(title: 'Dashboard'),
      ),
      GoRoute(
        path: '/reports/new',
        name: 'submit-report',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Submit Report'),
      ),
      GoRoute(
        path: '/reports/:id',
        name: 'report-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _PlaceholderPage(title: 'Report $id');
        },
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Global redirect — auth guard
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String?> _globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final hasToken = await _storage.hasTokens();
    final currentPath = state.matchedLocation;

    // Paths that don't require authentication.
    const publicPaths = {'/login', '/register', '/verify-email'};
    final isOnPublicPage = publicPaths.contains(currentPath);

    if (!hasToken && !isOnPublicPage) {
      // Not authenticated → send to login.
      return '/login';
    }

    if (hasToken && isOnPublicPage) {
      // Already authenticated → send to dashboard.
      return '/dashboard';
    }

    // No redirect needed.
    return null;
  }
}

// ─── Placeholder page  ─────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class AppRoutePaths {
  AppRoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String dashboard = '/dashboard';
  static const String submitReport = '/reports/new';
  static const String notifications = '/notifications';
  static const String staffDashboard = '/staff-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminCategories = '/admin/categories';
  static const String analytics = '/analytics';
  static const String reportDetailPattern = '/reports/:id';
  static const String staffReportDetailPattern = '/staff-reports/:id';

  static const Set<String> publicPaths = {
    splash,
    login,
    register,
    verifyEmail,
  };

  static String verifyEmailLocation({required String email}) {
    return Uri(
      path: verifyEmail,
      queryParameters: {'email': email},
    ).toString();
  }

  static String reportDetail(String id) => '/reports/$id';

  static String staffReportDetail(String id) => '/staff-reports/$id';

  static bool isAdminRoute(String path) {
    return path == adminDashboard || path.startsWith('/admin/');
  }

  static bool isCitizenOnlyRoute(String path) {
    return path == dashboard || path == submitReport;
  }

  static bool isStaffRoute(String path) {
    return path == staffDashboard || path.startsWith('/staff-reports');
  }
}

class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String verifyEmail = 'verify-email';
  static const String dashboard = 'dashboard';
  static const String submitReport = 'submit-report';
  static const String reportDetail = 'report-detail';
  static const String notifications = 'notifications';
  static const String staffDashboard = 'staff-dashboard';
  static const String staffReportDetail = 'staff-report-detail';
  static const String adminDashboard = 'admin-dashboard';
  static const String adminUsers = 'admin-users';
  static const String adminCategories = 'admin-categories';
  static const String analytics = 'analytics';
}

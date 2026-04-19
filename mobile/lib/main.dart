import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/storage/secure_storage_helper.dart';
import 'features/admin/services/admin_service.dart';
import 'features/admin/viewmodels/admin_view_model.dart';
import 'features/analytics/services/analytics_service.dart';
import 'features/analytics/viewmodels/analytics_view_model.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodels/auth_view_model.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/viewmodels/notification_view_model.dart';
import 'features/reports/services/category_service.dart';
import 'features/reports/services/report_service.dart';
import 'features/reports/viewmodels/report_view_model.dart';
import 'features/review/services/staff_report_service.dart';
import 'features/review/viewmodels/staff_workflow_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('vi', timeago.ViMessages());

  // Lock to portrait orientation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style system bars.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Core dependencies ──────────────────────────────────────────────────
  final storage = SecureStorageHelper();
  final dio = DioClient.create(storage: storage);

  // ── Feature services ───────────────────────────────────────────────────
  final authService = AuthService(dio: dio);
  final reportService = ReportService(dio: dio);
  final categoryService = CategoryService(dio: dio);
  final notificationService = NotificationService(dio: dio);
  final staffReportService = StaffReportService(dio: dio);
  final adminService = AdminService(dio: dio);
  final analyticsService = AnalyticsService(dio: dio);
  final authViewModel = AuthViewModel(
    authService: authService,
    storage: storage,
  )..tryAutoLogin();
  final appRouter = AppRouter(
    storage: storage,
    authViewModel: authViewModel,
  );

  runApp(
    MultiProvider(
      providers: [
        // Core
        ChangeNotifierProvider<SecureStorageHelper>.value(value: storage),
        Provider<Dio>.value(value: dio),
        Provider<AppRouter>.value(value: appRouter),

        // Auth
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),

        // Reports
        Provider<ReportService>.value(value: reportService),
        Provider<CategoryService>.value(value: categoryService),
        ChangeNotifierProvider<ReportViewModel>(
          create: (_) => ReportViewModel(
            reportService: reportService,
            categoryService: categoryService,
          ),
        ),

        // Staff Review Workflow
        Provider<StaffReportService>.value(value: staffReportService),
        ChangeNotifierProvider<StaffWorkflowViewModel>(
          create: (_) => StaffWorkflowViewModel(
            service: staffReportService,
            categoryService: categoryService,
          ),
        ),

        // Notifications
        ChangeNotifierProvider<NotificationViewModel>(
          create: (_) => NotificationViewModel(
            notificationService: notificationService,
            navigatorKey: appRouter.navigatorKey,
          ),
        ),

        // Admin
        Provider<AdminService>.value(value: adminService),
        ChangeNotifierProvider<AdminViewModel>(
          create: (_) => AdminViewModel(adminService: adminService),
        ),

        // Analytics
        Provider<AnalyticsService>.value(value: analyticsService),
        ChangeNotifierProvider<AnalyticsViewModel>(
          create: (_) => AnalyticsViewModel(service: analyticsService),
        ),
      ],
      child: const CityVoiceApp(),
    ),
  );

  // Request location permission AFTER the UI is rendered.
  _requestLocationPermission();
}

/// Requests location permission before the app launches.
Future<void> _requestLocationPermission() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  } catch (_) {
    // Swallow — location is not critical for app startup.
  }
}

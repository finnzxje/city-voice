import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/storage/secure_storage_helper.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodels/auth_view_model.dart';
import 'features/reports/services/category_service.dart';
import 'features/reports/services/notification_service.dart';
import 'features/reports/services/report_service.dart';
import 'features/reports/viewmodels/report_view_model.dart';
import 'features/review/services/staff_report_service.dart';
import 'features/review/viewmodels/staff_workflow_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Location permission is requested asynchronously after runApp
  // so the UI renders immediately without blocking.

  // ── Core dependencies ──────────────────────────────────────────────────
  final storage = SecureStorageHelper();
  final dio = DioClient.create(storage: storage);

  // ── Feature services ───────────────────────────────────────────────────
  final authService = AuthService(dio: dio);
  final reportService = ReportService(dio: dio);
  final categoryService = CategoryService(dio: dio);
  final notificationService = NotificationService(dio: dio);
  final staffReportService = StaffReportService(dio: dio);
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
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<ReportViewModel>(
          create: (_) => ReportViewModel(
            reportService: reportService,
            categoryService: categoryService,
            notificationService: notificationService,
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
      ],
      child: const CityVoiceApp(),
    ),
  );

  // Request location permission AFTER the UI is rendered.
  _requestLocationPermission();
}

/// Requests location permission before the app launches.
///
/// Steps:
///   1. Check if the device's location service is turned on.
///   2. If turned off → open system location settings.
///   3. Check permission status — request if [denied].
Future<void> _requestLocationPermission() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      // Re-check after returning from settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // If deniedForever, the user must go to app settings manually.
    // We don't block the app — the submit screen will handle it too.
  } catch (_) {
    // Swallow — location is not critical for app startup.
  }
}

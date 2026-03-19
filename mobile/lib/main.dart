import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/storage/secure_storage_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for a consistent civic-app experience.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style the system status bar and navigation bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Core dependencies (created once, shared app-wide) ──────────────────
  final storage = SecureStorageHelper();
  final dio = DioClient.create(storage: storage);
  final appRouter = AppRouter(storage: storage);

  runApp(
    /// [MultiProvider] makes core dependencies available to every widget
    /// and ViewModel via `context.read<T>()`.
    ///
    /// Feature-specific ViewModels will be registered on their own routes
    MultiProvider(
      providers: [
        Provider<SecureStorageHelper>.value(value: storage),
        Provider<Dio>.value(value: dio),
        Provider<AppRouter>.value(value: appRouter),
      ],
      child: const CityVoiceApp(),
    ),
  );
}

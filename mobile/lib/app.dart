import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget for the CityVoice mobile application.
///
/// Uses [GoRouter] (provided via [AppRouter]) for declarative,
/// auth-aware navigation, and applies the custom light/dark theme.
class CityVoiceApp extends StatelessWidget {
  const CityVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = context.read<AppRouter>();

    return MaterialApp.router(
      title: 'CityVoice',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Routing ────────────────────────────────────────────────────────
      routerConfig: appRouter.router,
    );
  }
}

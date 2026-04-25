import 'package:city_voice/app.dart';
import 'package:city_voice/core/routes/app_router.dart';
import 'package:city_voice/core/storage/secure_storage_helper.dart';
import 'package:city_voice/features/auth/services/auth_service.dart';
import 'package:city_voice/features/auth/viewmodels/auth_view_model.dart';
import 'package:city_voice/features/notifications/services/notification_service.dart';
import 'package:city_voice/features/notifications/viewmodels/notification_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('CityVoiceApp redirects unauthenticated users to login',
      (WidgetTester tester) async {
    final storage = _InMemorySecureStorageHelper();
    final authViewModel = AuthViewModel(
      authService: AuthService(dio: Dio()),
      storage: storage,
    );
    await authViewModel.tryAutoLogin();
    final appRouter = AppRouter(
      storage: storage,
      authViewModel: authViewModel,
    );
    final notificationViewModel = NotificationViewModel(
      notificationService: NotificationService(dio: Dio()),
      navigatorKey: appRouter.navigatorKey,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SecureStorageHelper>.value(value: storage),
          Provider<AppRouter>.value(value: appRouter),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          ChangeNotifierProvider<NotificationViewModel>.value(
            value: notificationViewModel,
          ),
        ],
        child: const CityVoiceApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}

class _InMemorySecureStorageHelper extends SecureStorageHelper {
  bool _hasTokens = false;
  String? _refreshToken;

  @override
  Future<bool> hasTokens() async => _hasTokens;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _hasTokens = true;
    _refreshToken = refreshToken;
    notifyListeners();
  }

  @override
  Future<void> clearAll() async {
    _hasTokens = false;
    _refreshToken = null;
    notifyListeners();
  }
}

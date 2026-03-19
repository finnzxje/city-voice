import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:city_voice/app.dart';
import 'package:city_voice/core/routes/app_router.dart';
import 'package:city_voice/core/storage/secure_storage_helper.dart';

void main() {
  testWidgets('CityVoiceApp builds without errors',
      (WidgetTester tester) async {
    final storage = SecureStorageHelper();
    final appRouter = AppRouter(storage: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SecureStorageHelper>.value(value: storage),
          Provider<AppRouter>.value(value: appRouter),
        ],
        child: const CityVoiceApp(),
      ),
    );

    // After the redirect guard runs, we should see the Login placeholder.
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:city_voice/app.dart';

void main() {
  testWidgets('CityVoiceApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CityVoiceApp());

    // Verify the app title and key UI elements render.
    expect(find.text('CityVoice'), findsWidgets);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}

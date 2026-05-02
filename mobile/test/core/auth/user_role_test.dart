import 'package:city_voice/core/auth/user_role.dart';
import 'package:city_voice/core/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('parses backend values safely', () {
      expect(UserRole.fromValue('admin'), UserRole.admin);
      expect(UserRole.fromValue('MANAGER'), UserRole.manager);
      expect(UserRole.fromValue('unknown'), UserRole.citizen);
      expect(UserRole.fromValue(null), UserRole.citizen);
    });

    test('maps each role to the correct home route', () {
      expect(UserRole.admin.homeRoute, AppRoutePaths.adminDashboard);
      expect(UserRole.manager.homeRoute, AppRoutePaths.analytics);
      expect(UserRole.staff.homeRoute, AppRoutePaths.staffDashboard);
      expect(UserRole.citizen.homeRoute, AppRoutePaths.dashboard);
    });
  });
}

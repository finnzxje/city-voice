import 'package:city_voice/core/auth/user_role.dart';
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
      expect(UserRole.admin.homeRoute, '/admin-dashboard');
      expect(UserRole.manager.homeRoute, '/analytics');
      expect(UserRole.staff.homeRoute, '/staff-dashboard');
      expect(UserRole.citizen.homeRoute, '/dashboard');
    });
  });
}

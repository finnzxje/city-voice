enum UserRole {
  citizen('citizen'),
  staff('staff'),
  manager('manager'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value?.toLowerCase(),
      orElse: () => UserRole.citizen,
    );
  }
}

extension UserRoleX on UserRole {
  bool get isCitizen => this == UserRole.citizen;

  bool get isStaffOrManager =>
      this == UserRole.staff || this == UserRole.manager;

  bool get isInternal => !isCitizen;

  bool get canAccessAnalytics =>
      this == UserRole.manager || this == UserRole.admin;

  String get homeRoute {
    return switch (this) {
      UserRole.admin => '/admin-dashboard',
      UserRole.manager => '/analytics',
      UserRole.staff => '/staff-dashboard',
      UserRole.citizen => '/dashboard',
    };
  }

  String get managementLabel {
    return switch (this) {
      UserRole.admin => 'Admin',
      UserRole.manager => 'Manager',
      UserRole.staff => 'Staff',
      UserRole.citizen => 'Citizen',
    };
  }

  String get staffDashboardBadgeLabel {
    return switch (this) {
      UserRole.admin => 'ADMIN',
      UserRole.manager => 'QUẢN LÝ',
      UserRole.staff => 'NHÂN VIÊN',
      UserRole.citizen => 'CƯ DÂN',
    };
  }
}

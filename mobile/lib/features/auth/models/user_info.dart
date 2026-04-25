import '../../../core/auth/user_role.dart';

/// Represents the authenticated user's profile.
///
/// Maps to the backend `UserInfoResponse` record returned by `GET /auth/me`:
/// ```json
/// {
///   "id": "uuid",
///   "email": "user@example.com",
///   "fullName": "Nguyen Van A",
///   "role": "citizen",
///   "isActive": true
/// }
/// ```
class UserInfo {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final bool isActive;

  const UserInfo({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      role: UserRole.fromValue(json['role']?.toString()),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.value,
        'isActive': isActive,
      };

  bool get isCitizen => role.isCitizen;

  bool get isInternal => role.isInternal;

  String get homeRoute => role.homeRoute;
}

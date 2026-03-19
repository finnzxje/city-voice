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
  final String role;
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
      role: (json['role']?.toString() ?? 'citizen').toLowerCase(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'isActive': isActive,
      };

  bool get isCitizen => role == 'citizen';

  bool get isInternal => role == 'staff' || role == 'manager' || role == 'admin';
}

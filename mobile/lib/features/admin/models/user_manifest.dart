class UserManifest {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  const UserManifest({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserManifest.fromJson(Map<String, dynamic> json) {
    return UserManifest(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: (json['role'] as String? ?? 'citizen').toLowerCase(),
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  UserManifest copyWith({String? role, bool? isActive}) {
    return UserManifest(
      id: id,
      email: email,
      fullName: fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

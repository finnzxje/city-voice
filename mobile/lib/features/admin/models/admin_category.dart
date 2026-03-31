class AdminCategory {
  final int id;
  final String name;
  final String slug;
  final String? iconKey;
  final bool active;

  const AdminCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.iconKey,
    required this.active,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      iconKey: json['iconKey'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  AdminCategory copyWith({
    String? name,
    String? slug,
    String? iconKey,
    bool? active,
  }) {
    return AdminCategory(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      iconKey: iconKey ?? this.iconKey,
      active: active ?? this.active,
    );
  }
}

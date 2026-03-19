/// Incident report category model.
///
/// Named `IncidentCategory` to avoid conflict with Flutter's
/// `Category` annotation from `package:flutter/foundation.dart`.
///
/// Maps to backend `CategoryResponse`:
/// ```json
/// { "id": 1, "name": "Ổ gà", "slug": "o-ga", "iconKey": "road" }
/// ```
class IncidentCategory {
  final int id;
  final String name;
  final String slug;
  final String? iconKey;

  const IncidentCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.iconKey,
  });

  factory IncidentCategory.fromJson(Map<String, dynamic> json) {
    return IncidentCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      iconKey: json['iconKey'] as String?,
    );
  }
}

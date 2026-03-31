/// Request body for creating or updating a category.
class UpsertCategoryRequest {
  final String name;
  final String slug;
  final String? iconKey;
  final bool active;

  const UpsertCategoryRequest({
    required this.name,
    required this.slug,
    this.iconKey,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'iconKey': iconKey,
        'active': active,
      };
}

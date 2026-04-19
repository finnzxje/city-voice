/// Mutable filter class used to build query params for analytics endpoints.
///
/// All fields are nullable — only non-null fields are sent as query params.
class AnalyticsFilter {
  String? from; // YYYY-MM-DD
  String? to; // YYYY-MM-DD
  int? categoryId;
  int? zoneId;
  String? priority; // 'low' | 'medium' | 'high' | 'critical'

  AnalyticsFilter({
    this.from,
    this.to,
    this.categoryId,
    this.zoneId,
    this.priority,
  });

  /// Returns only non-null fields as a map for Dio queryParameters.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (zoneId != null) params['zoneId'] = zoneId;
    if (priority != null) params['priority'] = priority;
    return params;
  }

  /// Returns true if any filter field is set.
  bool get hasActiveFilters =>
      from != null ||
      to != null ||
      categoryId != null ||
      zoneId != null ||
      priority != null;

  /// Creates a copy with optional overrides.
  AnalyticsFilter copyWith({
    String? Function()? from,
    String? Function()? to,
    int? Function()? categoryId,
    int? Function()? zoneId,
    String? Function()? priority,
  }) {
    return AnalyticsFilter(
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      zoneId: zoneId != null ? zoneId() : this.zoneId,
      priority: priority != null ? priority() : this.priority,
    );
  }
}

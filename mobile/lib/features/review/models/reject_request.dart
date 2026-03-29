/// Request body for `PUT /reports/{id}/reject`.
///
/// Transitions a report from `newly_received` → `rejected`.
class RejectRequest {
  final String note;

  const RejectRequest({required this.note});

  Map<String, dynamic> toJson() => {'note': note};
}

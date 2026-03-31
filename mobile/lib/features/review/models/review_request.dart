/// Request body for `PUT /reports/{id}/review`.
///
/// Transitions a report from `newly_received` → `in_progress` by assigning
/// a priority level and a responsible staff member.
class ReviewRequest {
  final String priority;
  final String assignedTo;
  final String? note;

  const ReviewRequest({
    required this.priority,
    required this.assignedTo,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'priority': priority,
        'assignedTo': assignedTo,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

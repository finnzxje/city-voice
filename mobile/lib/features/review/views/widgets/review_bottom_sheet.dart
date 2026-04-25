import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_view_model.dart';
import '../../viewmodels/staff_workflow_view_model.dart';

/// Bottom sheet for reviewing (approving) a report.
class ReviewBottomSheet extends StatefulWidget {
  final String reportId;

  const ReviewBottomSheet({super.key, required this.reportId});

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  String _selectedPriority = 'medium';
  late final TextEditingController _noteController;
  late final TextEditingController _assignedToController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    final authVm = context.read<AuthViewModel>();
    _assignedToController = TextEditingController(text: authVm.user?.id ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final assignedTo = _assignedToController.text.trim();
    if (assignedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng nhập UUID nhân viên phụ trách')));
      return;
    }
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.reviewReport(
        reportId: widget.reportId,
        priority: _selectedPriority,
        assignedTo: assignedTo,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim());
    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã duyệt báo cáo thành công!'),
          backgroundColor: AppColors.success));
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duyệt báo cáo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Mức ưu tiên *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPriority,
            isExpanded: true,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Thấp')),
              DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'high', child: Text('Cao')),
              DropdownMenuItem(value: 'critical', child: Text('Nghiêm trọng')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedPriority = v);
            },
          ),
          const SizedBox(height: 16),
          const Text('Phân công cho (UUID) *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _assignedToController,
            decoration: InputDecoration(
              hintText: 'UUID nhân viên phụ trách',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ghi chú',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ghi chú (không bắt buộc)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<StaffWorkflowViewModel>(
            builder: (_, vm, __) {
              if (vm.actionError != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.actionError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Consumer<StaffWorkflowViewModel>(
              builder: (_, vm, __) {
                return ElevatedButton(
                  onPressed: vm.isActionLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0044CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: vm.isActionLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Xác nhận duyệt',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to show the review bottom sheet.
void showReviewBottomSheet(BuildContext context, String reportId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => ReviewBottomSheet(reportId: reportId),
  );
}

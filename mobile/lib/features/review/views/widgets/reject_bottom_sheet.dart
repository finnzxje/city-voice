import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/staff_workflow_view_model.dart';
import 'review_action_bottom_sheet_layout.dart';

/// Bottom sheet for rejecting a report.
class RejectBottomSheet extends StatefulWidget {
  final String reportId;

  const RejectBottomSheet({super.key, required this.reportId});

  @override
  State<RejectBottomSheet> createState() => _RejectBottomSheetState();
}

class _RejectBottomSheetState extends State<RejectBottomSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập lý do từ chối')));
      return;
    }
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.rejectReport(reportId: widget.reportId, note: note);
    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã từ chối báo cáo.'),
          backgroundColor: AppColors.warning));
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReviewActionBottomSheetLayout(
      title: 'Từ chối báo cáo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lý do từ chối *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập lý do từ chối...',
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
                    backgroundColor: AppColors.error,
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
                      : const Text('Xác nhận từ chối',
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

/// Helper to show the reject bottom sheet.
void showRejectBottomSheet(BuildContext context, String reportId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => RejectBottomSheet(reportId: reportId),
  );
}

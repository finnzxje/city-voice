import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/staff_workflow_view_model.dart';

/// Bottom sheet for resolving a report with a proof image.
class ResolveBottomSheet extends StatefulWidget {
  final String reportId;

  const ResolveBottomSheet({super.key, required this.reportId});

  @override
  State<ResolveBottomSheet> createState() => _ResolveBottomSheetState();
}

class _ResolveBottomSheetState extends State<ResolveBottomSheet> {
  File? _selectedImage;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh xác nhận')));
      return;
    }
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final note = _noteController.text.trim();
    final ok = await vm.resolveReport(
        reportId: widget.reportId,
        imageFile: _selectedImage!,
        note: note.isEmpty ? null : note);
    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã xác nhận hoàn thành!'),
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
              const Text('Xác nhận hoàn thành',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Ảnh xác nhận hoàn thành *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _selectedImage != null
                        ? AppColors.success
                        : const Color(0xFFD1D5DB),
                    width: _selectedImage != null ? 2 : 1),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 36, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 8),
                        Text('Nhấn để chọn ảnh',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
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
                      : const Text('Hoàn thành',
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

/// Helper to show the resolve bottom sheet.
void showResolveBottomSheet(BuildContext context, String reportId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => ResolveBottomSheet(reportId: reportId),
  );
}

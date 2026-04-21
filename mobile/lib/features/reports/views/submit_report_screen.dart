import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/incident_category.dart';
import '../viewmodels/report_view_model.dart';
import 'submit_report/submit_report_form_controller.dart';
import 'submit_report/submit_report_form_sections.dart';
import 'widgets/map_picker_screen.dart';

/// Screen for submitting a new incident report.
class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formController = SubmitReportFormController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadCategories();
      _formController.detectLocation();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _formController.draft.location.initialMapLocation,
        ),
      ),
    );
    if (!mounted || pickedLocation == null) {
      return;
    }

    _formController.applyPickedLocation(pickedLocation);
  }

  Future<void> _showImageSourcePicker() {
    return showSubmitReportImageSourcePicker(
      context,
      onPickFromCamera: () => _formController.pickImage(ImageSource.camera),
      onPickFromGallery: () => _formController.pickImage(ImageSource.gallery),
    );
  }

  Future<void> _showCategoryPicker(List<IncidentCategory> categories) {
    return showSubmitReportCategoryPicker(
      context,
      categories: categories,
      selectedCategory: _formController.draft.selectedCategory,
      onSelected: _formController.selectCategory,
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final validationMessage = _formController.draft.submissionValidationMessage;
    if (validationMessage != null) {
      _showSnackBar(validationMessage, isError: true);
      return;
    }

    final draft = _formController.draft;
    final imageFile = draft.imageFile;
    final category = draft.selectedCategory;
    final latitude = draft.location.latitude;
    final longitude = draft.location.longitude;
    if (imageFile == null ||
        category == null ||
        latitude == null ||
        longitude == null) {
      _showSnackBar('Biểu mẫu báo cáo chưa hợp lệ.', isError: true);
      return;
    }

    final reportViewModel = context.read<ReportViewModel>();
    final newReportId = await reportViewModel.submitReport(
      title: _titleController.text.trim(),
      description: _trimmedDescription,
      categoryId: category.id,
      latitude: latitude,
      longitude: longitude,
      imageFile: imageFile,
    );
    if (!mounted) {
      return;
    }

    if (newReportId != null) {
      _showSnackBar('Báo cáo đã được gửi thành công!');
      context.pushReplacementNamed(
        'report-detail',
        pathParameters: {'id': newReportId},
      );
    } else if (reportViewModel.errorMessage != null) {
      _showSnackBar(reportViewModel.errorMessage!, isError: true);
    }
  }

  String? get _trimmedDescription {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      return null;
    }

    return description;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Báo cáo sự cố',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<ReportViewModel>(
        builder: (context, vm, _) {
          return AnimatedBuilder(
            animation: _formController,
            builder: (context, _) {
              final draft = _formController.draft;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SubmitReportSectionLabel(text: 'BẰNG CHỨNG'),
                      SubmitReportImageSection(
                        imageFile: draft.imageFile,
                        onTap: () => _showImageSourcePicker(),
                      ),
                      const SubmitReportSectionLabel(
                        text: 'DANH MỤC SỰ CỐ',
                      ),
                      SubmitReportCategoryField(
                        selectedCategory: draft.selectedCategory,
                        onTap: () => _showCategoryPicker(vm.categories),
                      ),
                      const SubmitReportSectionLabel(
                        text: 'TIÊU ĐỀ PHẢN ÁNH',
                      ),
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        maxLength: 200,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: buildSubmitReportInputDecoration(
                          hintText: 'VD: Ổ gà đường Nguyễn Huệ',
                        ).copyWith(
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }

                          return null;
                        },
                      ),
                      const SubmitReportSectionLabel(
                        text: 'CHI TIẾT BỔ SUNG (TÙY CHỌN)',
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        textInputAction: TextInputAction.newline,
                        maxLines: 4,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: buildSubmitReportInputDecoration(
                          hintText: 'Mô tả thêm về sự cố...',
                        ),
                      ),
                      const SubmitReportSectionLabel(text: 'VỊ TRÍ'),
                      SubmitReportLocationCard(
                        locationState: draft.location,
                        onTap: _openMapPicker,
                        onRefreshLocation: () =>
                            _formController.detectLocation(),
                      ),
                      const SizedBox(height: 32),
                      SubmitReportSubmitButton(
                        isSubmitting: vm.isSubmitting,
                        onPressed: vm.isSubmitting ? null : _handleSubmit,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

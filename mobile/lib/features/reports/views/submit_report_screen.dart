import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/incident_category.dart';
import '../viewmodels/report_view_model.dart';

/// Screen for submitting a new incident report.
///
/// Steps: pick image → auto-detect location → select category → fill title/description → submit.
class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  IncidentCategory? _selectedCategory;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadCategories();
      _detectLocation();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Vui lòng bật dịch vụ vị trí.';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Quyền vị trí bị từ chối.';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Không thể lấy vị trí. Vui lòng thử lại.';
        _isLocating = false;
      });
    }
  }

  // ── Image Picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_imageFile == null) {
      _showSnackBar('Vui lòng chọn ảnh sự cố.', isError: true);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar('Chưa xác định được vị trí. Vui lòng thử lại.',
          isError: true);
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('Vui lòng chọn danh mục sự cố.', isError: true);
      return;
    }

    final vm = context.read<ReportViewModel>();
    final success = await vm.submitReport(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _selectedCategory!.id,
      latitude: _latitude!,
      longitude: _longitude!,
      imageFile: _imageFile!,
    );

    if (success && mounted) {
      _showSnackBar('Báo cáo đã được gửi thành công!');
      context.pop();
    } else if (vm.errorMessage != null && mounted) {
      _showSnackBar(vm.errorMessage!, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo sự cố'),
        centerTitle: true,
      ),
      body: Consumer<ReportViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image picker ───────────────────────────────────────
                  _buildImageSection(theme),
                  const SizedBox(height: 20),

                  // ── Location ───────────────────────────────────────────
                  _buildLocationSection(theme),
                  const SizedBox(height: 20),

                  // ── Category dropdown ──────────────────────────────────
                  _buildCategoryDropdown(theme, vm),
                  const SizedBox(height: 18),

                  // ── Title ──────────────────────────────────────────────
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề *',
                      hintText: 'VD: Ổ gà đường Nguyễn Huệ',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Description ────────────────────────────────────────
                  TextFormField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.newline,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết (tuỳ chọn)',
                      hintText: 'Mô tả thêm về sự cố...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit button ──────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: vm.isSubmitting ? null : _handleSubmit,
                      child: vm.isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Gửi báo cáo'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section builders
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildImageSection(ThemeData theme) {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded,
                      size: 40, color: AppColors.textHint),
                  const SizedBox(height: 10),
                  Text(
                    'Nhấn để chọn ảnh sự cố *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          size: 18, color: Colors.white),
                      onPressed: _showImageSourcePicker,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _locationError != null
            ? AppColors.statusRejectedBg
            : _latitude != null
                ? AppColors.statusResolvedBg
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            _locationError != null
                ? Icons.location_off_outlined
                : _latitude != null
                    ? Icons.location_on_rounded
                    : Icons.my_location_rounded,
            color: _locationError != null
                ? AppColors.error
                : _latitude != null
                    ? AppColors.success
                    : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLocating
                ? Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đang xác định vị trí...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : _locationError != null
                    ? Text(
                        _locationError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vị trí đã xác định',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '${_latitude?.toStringAsFixed(5)}, ${_longitude?.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
          ),
          if (_locationError != null || (!_isLocating && _latitude != null))
            IconButton(
              onPressed: _detectLocation,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme, ReportViewModel vm) {
    return DropdownButtonFormField<IncidentCategory>(
      // ignore: deprecated_member_use
      value: _selectedCategory,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Danh mục sự cố *',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      hint: const Text('Chọn loại sự cố'),
      items: vm.categories.map((cat) {
        return DropdownMenuItem<IncidentCategory>(
          value: cat,
          child: Text(cat.name),
        );
      }).toList(),
      onChanged: (cat) => setState(() => _selectedCategory = cat),
      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
    );
  }
}

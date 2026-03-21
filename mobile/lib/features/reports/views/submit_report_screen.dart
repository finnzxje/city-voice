import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/incident_category.dart';
import '../viewmodels/report_view_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  // ── Location Logic ─────────────────────────────────────────────────────────

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

  // ── Image Picker Logic ─────────────────────────────────────────────────────

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
                    color: Color(0xFF2563EB)),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF2563EB)),
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

  // ── Submit Logic ───────────────────────────────────────────────────────────

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
    final String? newReportId = await vm.submitReport(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _selectedCategory!.id,
      latitude: _latitude!,
      longitude: _longitude!,
      imageFile: _imageFile!,
    );

    if (newReportId != null && mounted) {
      _showSnackBar('Báo cáo đã được gửi thành công!');
      context.pushReplacementNamed(
        'report-detail',
        pathParameters: {'id': newReportId},
      );
    } else if (vm.errorMessage != null && mounted) {
      _showSnackBar(vm.errorMessage!, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Builders
  // ═══════════════════════════════════════════════════════════════════════════

  // Label text form field
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 20.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color(0xFF334155), // Slate 700
        ),
      ),
    );
  }

  // style text form field
  InputDecoration _customInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFE2E8F0).withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // ── Hàm hiển thị Bottom Sheet chọn danh mục ──
  void _showCategoryPicker(List<IncidentCategory> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chọn danh mục sự cố',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory?.id == cat.id;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF334155),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image picker ───────────────────────────────────────────
                  _buildSectionLabel('BẰNG CHỨNG'),
                  _buildImageSection(theme),

                  // ── Category Selector ───────────────────────
                  _buildSectionLabel('DANH MỤC SỰ CỐ'),
                  GestureDetector(
                    onTap: () => _showCategoryPicker(vm.categories),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory?.name ?? 'Chọn loại sự cố...',
                            style: TextStyle(
                              color: _selectedCategory != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: _selectedCategory != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),

                  // ── Title ──────────────────────────────────────────────
                  _buildSectionLabel('TIÊU ĐỀ PHẢN ÁNH'),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: 200,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: _customInputDecoration(
                            hintText: 'VD: Ổ gà đường Nguyễn Huệ')
                        .copyWith(
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),

                  // ── Description ────────────────────────────────────────
                  _buildSectionLabel('CHI TIẾT BỔ SUNG (TÙY CHỌN)'),
                  TextFormField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.newline,
                    maxLines: 4,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: _customInputDecoration(
                        hintText: 'Mô tả thêm về sự cố...'),
                  ),

                  // ── Location Card ──────────────────────────────────────
                  _buildSectionLabel('VỊ TRÍ'),
                  _buildLocationCard(),

                  const SizedBox(height: 32),

                  // ── Submit button ──────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: vm.isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: vm.isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
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
                                Text(
                                  'Gửi báo cáo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Incident image ─────────────────────────────────────
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

  // ── Widget Location Card  ──────────────
  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // flutter map
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _isLocating
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : (_latitude != null && _longitude != null)
                      ? FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(_latitude!, _longitude!),
                            initialZoom: 16.0,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.cityvoice',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_latitude!, _longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Center(
                            child: Icon(Icons.location_off_outlined,
                                size: 40, color: Color(0xFF94A3B8)),
                          ),
                        ),
            ),
          ),

          // Thông tin tọa độ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon mũi tên định vị
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.near_me,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Text thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationError != null
                            ? 'Lỗi vị trí'
                            : (_isLocating
                                ? 'Đang tìm vị trí...'
                                : 'Vị trí hiện tại'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _locationError != null
                              ? Colors.red
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locationError ??
                            (_latitude != null
                                ? '${_latitude?.toStringAsFixed(5)}, ${_longitude?.toStringAsFixed(5)}'
                                : 'Chưa xác định được tọa độ'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Nút Làm mới
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Nền xanh nhạt
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _isLocating ? null : _detectLocation,
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFF2563EB),
                    tooltip: 'Làm mới vị trí',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

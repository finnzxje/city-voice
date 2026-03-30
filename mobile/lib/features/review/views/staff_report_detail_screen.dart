import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/utils.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/report.dart';
import '../viewmodels/staff_workflow_view_model.dart';

/// Staff-facing report detail screen.
///
/// Shows full information including staff-only fields (priority, citizen,
/// assignee) and context-sensitive action buttons at the bottom based on
/// the report's current status.
class StaffReportDetailScreen extends StatefulWidget {
  final String reportId;

  const StaffReportDetailScreen({super.key, required this.reportId});

  @override
  State<StaffReportDetailScreen> createState() =>
      _StaffReportDetailScreenState();
}

class _StaffReportDetailScreenState extends State<StaffReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffWorkflowViewModel>().loadReportDetail(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Chi tiết báo cáo',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Consumer<StaffWorkflowViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              );
            }
            if (vm.errorMessage != null && vm.selectedReport == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(vm.errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: () => vm.loadReportDetail(widget.reportId),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            final report = vm.selectedReport;
            if (report == null) {
              return const Center(
                child: Text('Không tìm thấy báo cáo.'),
              );
            }
            return _buildBody(report, vm);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Body
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBody(Report report, StaffWorkflowViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Hero image ─────────────────────────────────────
              _buildHeroImage(report),

              // ── Content sheet ──────────────────────────────────
              Container(
                transform: Matrix4.translationValues(0, -24, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category & Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: report.categoryName
                                    .replaceAll(' / ', '\n')
                                    .replaceAll('/', '\n'),
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '   •   ${DateFormat('dd/MM/yyyy').format(report.createdAt)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status chip
                    _buildStatusChip(report),
                    const SizedBox(height: 20),

                    // ── Staff info section ────────────────────────────
                    _buildStaffInfoSection(report),

                    // ── Description ──────────────────────────────────
                    if (report.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      const Text('MÔ TẢ',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 10),
                      Text(report.description!,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF475569),
                              height: 1.5)),
                    ],
                    const SizedBox(height: 24),

                    // ── Location card ────────────────────────────────
                    _buildLocationCard(report),

                    // ── Resolution image ─────────────────────────────
                    if (report.resolutionImageUrl != null) ...[
                      const SizedBox(height: 24),
                      const Text('ẢNH XÁC NHẬN',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          Utils.getSafeUrl(report.resolutionImageUrl),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 40, color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Bottom action bar ───────────────────────────────────
        _buildActionBar(report),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sub-widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroImage(Report report) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: report.incidentImageUrl != null
          ? Image.network(
              Utils.getSafeUrl(report.incidentImageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE2E8F0),
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 48, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          : Container(
              color: const Color(0xFFE2E8F0),
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    size: 48, color: Color(0xFF94A3B8)),
              ),
            ),
    );
  }

  Widget _buildStatusChip(Report report) {
    final statusColor = AppColors.statusColor(report.currentStatus);
    final statusBg = AppColors.statusBackgroundColor(report.currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(report.statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStaffInfoSection(Report report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Người báo cáo',
              report.citizenName ?? 'Ẩn danh'),
          if (report.priority != null) ...[
            const SizedBox(height: 12),
            _infoRow(Icons.flag_outlined, 'Mức ưu tiên',
                report.priorityLabel ?? report.priority!,
                valueColor: AppColors.priorityColor(report.priority)),
          ],
          if (report.assignedToName != null) ...[
            const SizedBox(height: 12),
            _infoRow(Icons.assignment_ind_outlined, 'Phụ trách',
                report.assignedToName!),
          ],
          const SizedBox(height: 12),
          _infoRow(Icons.location_city_outlined, 'Khu vực',
              report.administrativeZoneName ?? 'Chưa xác định'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              Flexible(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? const Color(0xFF1E293B)),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Report report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(report.latitude, report.longitude),
                  initialZoom: 15.0,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cityvoice',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(report.latitude, report.longitude),
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.location_on,
                          color: Colors.redAccent, size: 24),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.administrativeZoneName ?? 'Hồ Chí Minh',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.2)),
                const SizedBox(height: 4),
                Text(
                    '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Action Bar at bottom
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionBar(Report report) {
    final status = report.currentStatus;

    if (status == 'resolved') {
      return _buildStatusBanner(
        icon: Icons.check_circle_outline,
        text:
            'Đã giải quyết vào ${DateFormat('dd/MM/yyyy').format(report.resolvedAt ?? report.updatedAt ?? DateTime.now())}',
        color: AppColors.success,
        bgColor: AppColors.statusResolvedBg,
      );
    }

    if (status == 'rejected') {
      return _buildStatusBanner(
        icon: Icons.cancel_outlined,
        text: 'Báo cáo đã bị từ chối',
        color: AppColors.error,
        bgColor: AppColors.statusRejectedBg,
      );
    }

    if (status == 'newly_received') {
      return _buildActionContainer(
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Duyệt',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
                onTap: () => _showReviewSheet(report),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Từ chối',
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                isOutlined: true,
                onTap: () => _showRejectSheet(report),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'in_progress') {
      return _buildActionContainer(
        child: _ActionButton(
          label: 'Xác nhận hoàn thành',
          icon: Icons.task_alt_outlined,
          color: AppColors.success,
          onTap: () => _showResolveSheet(report),
          isFullWidth: true,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom Sheets
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReviewSheet(Report report) {
    String selectedPriority = 'medium';
    final noteController = TextEditingController();
    final authVm = context.read<AuthViewModel>();
    final assignedToController = TextEditingController(
      text: authVm.user?.id ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duyệt báo cáo',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Priority dropdown
                  const Text('Mức ưu tiên *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  // ignore: deprecated_member_use
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                      DropdownMenuItem(
                          value: 'medium', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                      DropdownMenuItem(
                          value: 'critical', child: Text('Nghiêm trọng')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedPriority = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Assigned to
                  const Text('Phân công cho (UUID) *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: assignedToController,
                    decoration: InputDecoration(
                      hintText: 'UUID nhân viên phụ trách',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  const Text('Ghi chú',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ghi chú (không bắt buộc)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action errors
                  Consumer<StaffWorkflowViewModel>(
                    builder: (_, vm, __) {
                      if (vm.actionError != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(vm.actionError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Consumer<StaffWorkflowViewModel>(
                      builder: (_, vm, __) {
                        return ElevatedButton(
                          onPressed: vm.isActionLoading
                              ? null
                              : () => _submitReview(
                                    ctx,
                                    report.id,
                                    selectedPriority,
                                    assignedToController.text.trim(),
                                    noteController.text.trim(),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: vm.isActionLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Text('Xác nhận duyệt',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectSheet(Report report) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Từ chối báo cáo',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Lý do từ chối *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569))),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do từ chối...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Action errors
              Consumer<StaffWorkflowViewModel>(
                builder: (_, vm, __) {
                  if (vm.actionError != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(vm.actionError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
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
                      onPressed: vm.isActionLoading
                          ? null
                          : () {
                              final note = noteController.text.trim();
                              if (note.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Vui lòng nhập lý do từ chối')),
                                );
                                return;
                              }
                              _submitReject(ctx, report.id, note);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
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
      },
    );
  }

  void _showResolveSheet(Report report) {
    File? selectedImage;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Xác nhận hoàn thành',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image picker
                  const Text('Ảnh xác nhận hoàn thành *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1080,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setSheetState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedImage != null
                              ? AppColors.success
                              : const Color(0xFFCBD5E1),
                          width: selectedImage != null ? 2 : 1,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child:
                                  Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 36, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  const Text('Ghi chú',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ghi chú (không bắt buộc)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action errors
                  Consumer<StaffWorkflowViewModel>(
                    builder: (_, vm, __) {
                      if (vm.actionError != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(vm.actionError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
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
                          onPressed: vm.isActionLoading
                              ? null
                              : () {
                                  if (selectedImage == null) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Vui lòng chọn ảnh xác nhận')),
                                    );
                                    return;
                                  }
                                  _submitResolve(
                                    ctx,
                                    report.id,
                                    selectedImage!,
                                    noteController.text.trim(),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: vm.isActionLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Text('Hoàn thành',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Action handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _submitReview(
    BuildContext sheetCtx,
    String reportId,
    String priority,
    String assignedTo,
    String note,
  ) async {
    if (assignedTo.isEmpty) {
      ScaffoldMessenger.of(sheetCtx).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập UUID nhân viên phụ trách')),
      );
      return;
    }

    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(sheetCtx);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.reviewReport(
      reportId: reportId,
      priority: priority,
      assignedTo: assignedTo,
      note: note.isEmpty ? null : note,
    );

    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt báo cáo thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      router.pop();
    }
  }

  Future<void> _submitReject(
      BuildContext sheetCtx, String reportId, String note) async {
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(sheetCtx);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.rejectReport(reportId: reportId, note: note);

    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối báo cáo.'),
          backgroundColor: AppColors.warning,
        ),
      );
      router.pop();
    }
  }

  Future<void> _submitResolve(
    BuildContext sheetCtx,
    String reportId,
    File imageFile,
    String note,
  ) async {
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(sheetCtx);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.resolveReport(
      reportId: reportId,
      imageFile: imageFile,
      note: note.isEmpty ? null : note,
    );

    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận hoàn thành!'),
          backgroundColor: AppColors.success,
        ),
      );
      router.pop();
    }
  }
}

// ─── Reusable action button ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;
  final bool isFullWidth;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        height: 52,
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

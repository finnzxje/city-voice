import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/utils.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../reports/models/report.dart';
import '../viewmodels/staff_workflow_view_model.dart';

/// Staff-facing report detail screen.
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
        backgroundColor: const Color(0xFFF8F9FA), // Nền xám rất nhạt
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0033CC)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Chi tiết báo cáo',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF0033CC)),
              onPressed: () {
                // TODO: Show options menu
              },
            ),
          ],
        ),
        body: Consumer<StaffWorkflowViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0033CC)),
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
  // Body Layout
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBody(Report report, StaffWorkflowViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // ── Hero Image & Floating Tags ─────────────────────────────────
              _buildHeroSection(report),

              // ── Overlapping Main Info Card ─────────────────────────────────
              _buildMainInfoCard(report),

              // ── Details List Card ──────────────────────────────────────────
              _buildDetailsList(report),

              // ── Description Section ────────────────────────────────────────
              _buildDescription(report),

              // ── Map Section ────────────────────────────────────────────────
              _buildMapSection(report),

              // ── Resolution Image (If resolved) ─────────────────────────────
              if (report.resolutionImageUrl != null) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'ẢNH XÁC NHẬN HOÀN THÀNH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      Utils.getSafeUrl(report.resolutionImageUrl),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Bottom Action Bar ────────────────────────────────────────────────
        _buildActionBar(report),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroSection(Report report) {
    final statusColor = AppColors.statusColor(report.currentStatus);

    return Stack(
      children: [
        // Image
        SizedBox(
          height: 280,
          width: double.infinity,
          child: report.incidentImageUrl != null
              ? Image.network(
                  Utils.getSafeUrl(report.incidentImageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFE5E7EB)),
                )
              : Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 48, color: Color(0xFF9CA3AF)),
                  ),
                ),
        ),
        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFF8F9FA).withOpacity(1.0),
                  const Color(0xFFF8F9FA).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // ── Top Left Tag (Status Only) ──
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusBackgroundColor(report.currentStatus),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              report.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // ── Top Right Date Badge ──
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Color(0xFF0033CC)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(report.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfoCard(Report report) {
    return Container(
      transform: Matrix4.translationValues(0, -40, 0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0033CC), // Màu xanh dương đậm
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Category Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.label_important,
                    color: Color(0xFF0033CC), size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'Phân loại: '),
                      TextSpan(
                        text: report.categoryName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList(Report report) {
    return Container(
      transform: Matrix4.translationValues(0, -20, 0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
              icon: Icons.person,
              iconColor: const Color(0xFF0044CC), // Xanh dương
              label: 'NGƯỜI BÁO CÁO',
              value: report.citizenName ?? 'Ẩn danh'),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _buildDetailRow(
              icon: Icons.manage_accounts,
              iconColor: const Color(0xFF4B5563), // Xám đậm
              label: 'PHỤ TRÁCH',
              value: report.assignedToName ?? 'Chưa phân công'),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _buildDetailRow(
              icon: Icons.flag,
              iconColor: AppColors.priorityColor(report.priority),
              label: 'ĐỘ ƯU TIÊN',
              value: report.priorityLabel ?? 'Chưa rõ',
              valueColor: AppColors.priorityColor(report.priority)),
          const Divider(
              height: 1, color: Color(0xFFE5E7EB), indent: 48, endIndent: 16),
          _buildDetailRow(
              icon: Icons.location_on,
              iconColor: const Color.fromARGB(255, 15, 148, 59),
              label: 'KHU VỰC',
              value: report.administrativeZoneName ?? 'Chưa rõ'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      {required IconData icon,
      required Color iconColor,
      required String label,
      required String value,
      Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14), // Giảm padding dọc một chút
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10, // Cỡ chữ nhỏ hơn
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11, // Cỡ chữ nhỏ hơn
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Report report) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÔ TẢ CHI TIẾT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Nền xám nhạt
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              report.description?.isNotEmpty == true
                  ? report.description!
                  : 'Không có mô tả chi tiết.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Report report) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              // Map
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(report.latitude, report.longitude),
                  initialZoom: 16.0,
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
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_on,
                          color: Color(0xFFE53E3E), size: 56), // Pin đỏ to
                    ),
                  ]),
                ],
              ),
              // Dark gradient overlay to make button pop
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
              // "MỞ BẢN ĐỒ" Button
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.map, size: 14, color: Color(0xFF0033CC)),
                      SizedBox(width: 6),
                      Text(
                        'MỞ BẢN ĐỒ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom Action Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionBar(Report report) {
    final status = report.currentStatus;
    final authVm = context.read<AuthViewModel>();
    final currentUserId = authVm.user?.id;
    final currentUserRole = authVm.user?.role;
    final canResolve = currentUserRole == 'admin' ||
        (currentUserId != null &&
            report.assignedToId != null &&
            report.assignedToId == currentUserId);

    if (status == 'resolved') {
      return _buildStatusBanner(
        icon: Icons.check_circle,
        text:
            'Đã giải quyết vào ${DateFormat('dd/MM/yyyy').format(report.resolvedAt ?? report.updatedAt ?? DateTime.now())}',
        color: AppColors.success,
        bgColor: AppColors.statusResolvedBg,
      );
    }

    if (status == 'rejected') {
      return _buildStatusBanner(
        icon: Icons.cancel,
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
                label: 'Từ chối',
                icon: Icons.close,
                color: Colors.white,
                textColor: const Color(0xFF111827),
                isOutlined: true,
                onTap: () => _showRejectSheet(report),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                label: 'Duyệt',
                icon: Icons.check,
                color: const Color(0xFF0044CC),
                textColor: Colors.white,
                onTap: () => _showReviewSheet(report),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'in_progress') {
      return _buildActionContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canResolve) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.warning.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chỉ nhân viên được giao mới có thể xác nhận hoàn thành.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _ActionButton(
              label: 'Xác nhận hoàn thành',
              icon: Icons.check_circle,
              color: const Color(0xFF0044CC),
              // Màu xanh dương đậm
              textColor: Colors.white,
              onTap: canResolve
                  ? () => _showResolveSheet(report)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Chỉ nhân viên được giao mới có thể thực hiện thao tác này.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
              isFullWidth: true,
            ),
          ],
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
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: color.withOpacity(0.3))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA), // Khớp với màu nền
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom Sheets (Logic kept from original)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReviewSheet(Report report) {
    String selectedPriority = 'medium';
    final noteController = TextEditingController();
    final authVm = context.read<AuthViewModel>();
    final assignedToController =
        TextEditingController(text: authVm.user?.id ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      const Text('Duyệt báo cáo',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Mức ưu tiên *',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
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
                  const Text('Phân công cho (UUID) *',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                  const Text('Ghi chú',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                              : () => _submitReview(
                                  ctx,
                                  report.id,
                                  selectedPriority,
                                  assignedToController.text.trim(),
                                  noteController.text.trim()),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Lý do từ chối *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                                        content: Text(
                                            'Vui lòng nhập lý do từ chối')));
                                return;
                              }
                              _submitReject(ctx, report.id, note);
                            },
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
      },
    );
  }

  void _showResolveSheet(Report report) {
    File? selectedImage;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Ảnh xác nhận hoàn thành *',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1920,
                          maxHeight: 1080,
                          imageQuality: 85);
                      if (picked != null)
                        setSheetState(() => selectedImage = File(picked.path));
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selectedImage != null
                                ? AppColors.success
                                : const Color(0xFFD1D5DB),
                            width: selectedImage != null ? 2 : 1),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child:
                                  Image.file(selectedImage!, fit: BoxFit.cover))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 36, color: Color(0xFF9CA3AF)),
                                SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh',
                                    style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ghi chú',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                                                'Vui lòng chọn ảnh xác nhận')));
                                    return;
                                  }
                                  _submitResolve(ctx, report.id, selectedImage!,
                                      noteController.text.trim());
                                },
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
  // Action Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _submitReview(BuildContext sheetCtx, String reportId,
      String priority, String assignedTo, String note) async {
    if (assignedTo.isEmpty) {
      ScaffoldMessenger.of(sheetCtx).showSnackBar(const SnackBar(
          content: Text('Vui lòng nhập UUID nhân viên phụ trách')));
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
        note: note.isEmpty ? null : note);
    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã duyệt báo cáo thành công!'),
          backgroundColor: AppColors.success));
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
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã từ chối báo cáo.'),
          backgroundColor: AppColors.warning));
      router.pop();
    }
  }

  Future<void> _submitResolve(BuildContext sheetCtx, String reportId,
      File imageFile, String note) async {
    final vm = context.read<StaffWorkflowViewModel>();
    final navigator = Navigator.of(sheetCtx);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await vm.resolveReport(
        reportId: reportId,
        imageFile: imageFile,
        note: note.isEmpty ? null : note);
    if (ok && mounted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Đã xác nhận hoàn thành!'),
          backgroundColor: AppColors.success));
      router.pop();
    }
  }
}

// ─── Reusable Action Button ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool isOutlined;
  final bool isFullWidth;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.isOutlined = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        height: 54,
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            backgroundColor: color,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/utils.dart';
import '../viewmodels/report_view_model.dart';
import '../models/report.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B5E44); // dark-green: completed steps
const _kBlue = Color(0xFF2563EB); // royal-blue: current when newly_received
const _kOrange = Color(0xFFF59E0B); // amber: current when in_progress
const _kGrey = Color(0xFFCBD5E1); // pending node
const _kGreyLine = Color(0xFFE2E8F0); // pending connector
const _kGreenLine = Color(0xFF1B5E44); // completed connector

// ── Node visual styles ────────────────────────────────────────────────────────
enum _NodeStyle {
  doneGreen, // dark-green filled + white ✓  (completed step)
  currentBlue, // royal-blue filled + white ✓  (active when newly_received)
  currentOrange, // amber filled + white wrench   (active when in_progress)
  pendingGrey, // grey filled + faded icon      (not yet reached)
  rejected, // red filled + white ✗
}

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadReportDetail(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Chi tiết phản ánh',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF2563EB)),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<ReportViewModel>(
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
              return const Center(child: Text('Không tìm thấy phản ánh'));
            }
            return _buildContent(report);
          },
        ),
      ),
    );
  }

  // ── Main scroll body ───────────────────────────────────────────────────────
  Widget _buildContent(Report report) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Hero image — full-bleed behind AppBar
        SizedBox(
          height: 280,
          width: double.infinity,
          child: report.incidentImageUrl != null
              ? Image.network(
                  Utils.getSafeUrl(report.incidentImageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderHero(),
                )
              : _buildPlaceholderHero(),
        ),

        Transform.translate(
          offset: const Offset(0, -24),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white, // Thẻ màu trắng
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Category + date
                _buildCategoryRow(report),
                const SizedBox(height: 24),

                // Description
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  report.description?.isNotEmpty == true
                      ? report.description!
                      : 'Không có mô tả chi tiết cho sự cố này.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),

                // Location card
                _buildLocationCard(report),
                const SizedBox(height: 32),

                // Timeline
                const Text(
                  'Tiến trình xử lý',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTimeline(report),
                const SizedBox(height: 32),

                // Get Notifications button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã bật thông báo cho phản ánh này.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 20),
                    label: const Text(
                      'Nhận thông báo',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom status hint
                Center(
                  child: Text(
                    _getBottomStatusText(report.currentStatus),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Category + date row ────────────────────────────────────────────────────
  Widget _buildCategoryRow(Report report) {
    final dateText = DateFormat('dd/MM/yyyy').format(report.createdAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: Icon(Icons.location_on_outlined,
              size: 18, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                report.categoryName ?? '',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  '•',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
              Text(
                dateText,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero placeholder ───────────────────────────────────────────────────────
  Widget _buildPlaceholderHero() {
    return Container(
      color: const Color(0xFF94A3B8),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 48, color: Colors.white54),
      ),
    );
  }

  // ── Location card ──────────────────────────────────────────────────────────
  Widget _buildLocationCard(Report report) {
    final statusText = switch (report.currentStatus) {
      'newly_received' => 'CHỜ PHÂN CÔNG',
      'in_progress' => 'CHỜ XỬ LÝ',
      'resolved' => 'ĐÃ XỬ LÝ',
      'rejected' => 'BỊ TỪ CHỐI',
      _ => 'KHÔNG RÕ TRẠNG THÁI',
    };
    final statusColor = switch (report.currentStatus) {
      'resolved' => const Color(0xFF16A34A),
      'rejected' => const Color(0xFFDC2626),
      _ => const Color(0xFF2563EB),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Map thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
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
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.location_on,
                            color: Colors.redAccent, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.8,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.administrativeZoneName ?? 'Hồ Chí Minh',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.latitude.toStringAsFixed(5)}, '
                  '${report.longitude.toStringAsFixed(5)}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline builder ───────────────────────────────────────────────────────
  Widget _buildTimeline(Report report) {
    final s = report.currentStatus;

    final _NodeStyle s0, s1, s2;
    bool isCurrent0 = false;
    bool isCurrent1 = false;
    bool isCurrent2 = false;

    switch (s) {
      case 'newly_received':
        s0 = _NodeStyle.currentBlue;
        isCurrent0 = true;
        s1 = _NodeStyle.pendingGrey;
        s2 = _NodeStyle.pendingGrey;
        break;
      case 'in_progress':
        s0 = _NodeStyle.doneGreen;
        s1 = _NodeStyle.currentOrange;
        isCurrent1 = true;
        s2 = _NodeStyle.pendingGrey;
        break;
      case 'resolved':
        s0 = _NodeStyle.doneGreen;
        s1 = _NodeStyle.doneGreen;
        s2 = _NodeStyle.doneGreen;
        isCurrent2 = true;
        break;
      case 'rejected':
        s0 = _NodeStyle.doneGreen;
        s1 = _NodeStyle.doneGreen;
        s2 = _NodeStyle.rejected;
        isCurrent2 = true;
        break;
      default:
        s0 = _NodeStyle.currentBlue;
        isCurrent0 = true;
        s1 = _NodeStyle.pendingGrey;
        s2 = _NodeStyle.pendingGrey;
    }

    bool _isActive(_NodeStyle style) =>
        style == _NodeStyle.doneGreen ||
        style == _NodeStyle.currentBlue ||
        style == _NodeStyle.currentOrange ||
        style == _NodeStyle.rejected;

    final line0 = _isActive(s1) ? _kGreenLine : _kGreyLine;
    final line1 = _isActive(s2) ? _kGreenLine : _kGreyLine;

    // Step 1 title
    final step1Title =
        report.assignedToName != null && report.assignedToName!.isNotEmpty
            ? 'Đang xử lý - Đã giao cho ${report.assignedToName}'
            : 'Đang xử lý';

    final step1Date = (s == 'in_progress' || s == 'resolved' || s == 'rejected')
        ? report.updatedAt
        : null;

    return Column(
      children: [
        _TimelineStep(
          title: 'Mới tiếp nhận',
          date: report.createdAt,
          nodeStyle: s0,
          lineColor: line0,
          isLast: false,
          isResolvedNode: false,
          isCurrent: isCurrent0,
        ),
        _TimelineStep(
          title: step1Title,
          date: step1Date,
          fallbackSubtitle: s == 'newly_received' ? 'Đang chờ phân công' : null,
          nodeStyle: s1,
          lineColor: line1,
          isLast: false,
          isResolvedNode: false,
          isCurrent: isCurrent1,
        ),
        if (s != 'rejected')
          _TimelineStep(
            title: 'Đã xử lý',
            date: report.resolvedAt,
            fallbackSubtitle: s != 'resolved' ? 'Đang chờ xử lý' : null,
            nodeStyle: s2,
            lineColor: _kGreyLine,
            isLast: true,
            isResolvedNode: true,
            isCurrent: isCurrent2,
          )
        else
          _TimelineStep(
            title: 'Từ chối',
            date: report.resolvedAt,
            nodeStyle: s2,
            lineColor: _kGreyLine,
            isLast: true,
            isResolvedNode: false,
            isCurrent: isCurrent2,
          ),
      ],
    );
  }

  String _getBottomStatusText(String status) {
    return switch (status) {
      'newly_received' => 'Đang chờ phân công',
      'in_progress' => 'Đang chờ xử lý',
      'resolved' => 'Sự cố đã được khắc phục',
      'rejected' => 'Sự cố đã bị từ chối',
      _ => 'Đang chờ cập nhật',
    };
  }
}

// ─── Floating circle icon button ──────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Timeline Step Widget ─────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String title;
  final DateTime? date;
  final String? fallbackSubtitle;
  final _NodeStyle nodeStyle;
  final Color lineColor;
  final bool isLast;
  final bool isResolvedNode;
  final bool isCurrent;

  const _TimelineStep({
    required this.title,
    this.date,
    this.fallbackSubtitle,
    required this.nodeStyle,
    required this.lineColor,
    required this.isLast,
    required this.isResolvedNode,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeBg;
    final Color titleColor;
    final Color subtitleColor;
    final IconData iconData;
    final Color iconColor;

    final double iconSize = isCurrent ? 16.0 : 12.0;

    switch (nodeStyle) {
      case _NodeStyle.doneGreen:
        nodeBg = _kGreen;
        titleColor = const Color(0xFF1E293B);
        subtitleColor = const Color(0xFF94A3B8);
        iconData = isResolvedNode ? Icons.verified_outlined : Icons.check;
        iconColor = Colors.white;
        break;
      case _NodeStyle.currentBlue:
        nodeBg = _kBlue;
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.check;
        iconColor = Colors.white;
        break;
      case _NodeStyle.currentOrange:
        nodeBg = _kOrange;
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.handyman;
        iconColor = Colors.white;
        break;
      case _NodeStyle.pendingGrey:
        nodeBg = _kGrey;
        titleColor = const Color(0xFF94A3B8);
        subtitleColor = const Color(0xFFCBD5E1);
        iconData = isResolvedNode ? Icons.verified_outlined : Icons.handyman;
        iconColor = Colors.white;
        break;
      case _NodeStyle.rejected:
        nodeBg = const Color(0xFFDC2626);
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.close;
        iconColor = Colors.white;
        break;
    }

    final displaySubtitle = date != null
        ? '${DateFormat('dd/MM/yyyy').format(date!)} • '
            '${DateFormat('HH:mm').format(date!)}'
        : (fallbackSubtitle ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: circle node + connector ─────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Vẽ Node
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: isCurrent
                        ? Container(
                            // Vòng halo mờ bên ngoài cho node hiện tại
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: nodeBg.withOpacity(0.2), // Màu mờ
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                // Hình tròn đậm bên trong
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: nodeBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData,
                                    size: iconSize, color: iconColor),
                              ),
                            ),
                          )
                        : Container(
                            // Node bình thường (quá khứ/tương lai) sẽ nhỏ hơn
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: nodeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData,
                                size: iconSize, color: iconColor),
                          ),
                  ),
                ),
                // Vẽ đường thẳng nối
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: lineColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Right: title + subtitle ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 28.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  if (displaySubtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      displaySubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

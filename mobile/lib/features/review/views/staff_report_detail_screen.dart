import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_cached_network_image.dart';
import '../../../core/utils/utils.dart';
import '../../reports/models/report.dart';
import '../viewmodels/staff_workflow_view_model.dart';
import 'widgets/details_list_card.dart';
import 'widgets/hero_section.dart';
import 'widgets/main_info_card.dart';
import 'widgets/reject_bottom_sheet.dart';
import 'widgets/report_map_section.dart';
import 'widgets/resolve_bottom_sheet.dart';
import 'widgets/review_bottom_sheet.dart';
import 'widgets/staff_action_bar.dart';

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
        backgroundColor: const Color(0xFFF8F9FA),
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
            return _buildBody(report);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Body Layout
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBody(Report report) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              HeroSection(report: report),
              MainInfoCard(report: report),
              DetailsListCard(report: report),
              _buildDescription(report),
              ReportMapSection(report: report),

              // ── Resolution Image (if resolved) ──
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
                    child: AppCachedNetworkImage(
                      imageUrl: Utils.getSafeUrl(report.resolutionImageUrl),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 1200,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Bottom Action Bar ──
        StaffActionBar(
          report: report,
          onReview: () => showReviewBottomSheet(context, report.id),
          onReject: () => showRejectBottomSheet(context, report.id),
          onResolve: () => showResolveBottomSheet(context, report.id),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Description section (kept inline — small enough)
  // ═══════════════════════════════════════════════════════════════════════════

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
              color: const Color(0xFFF3F4F6),
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
}

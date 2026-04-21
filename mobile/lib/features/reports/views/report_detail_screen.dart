import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/report_view_model.dart';
import 'report_detail/report_detail_sections.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  final String reportId;

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

  void _showNotificationsEnabledSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã bật thông báo cho phản ánh này.'),
        backgroundColor: Colors.green,
      ),
    );
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
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              );
            }

            final selectedReport = viewModel.selectedReport;
            final errorMessage = viewModel.errorMessage;

            if (errorMessage != null && selectedReport == null) {
              return ReportDetailErrorState(
                message: errorMessage,
                onRetry: () => viewModel.loadReportDetail(widget.reportId),
              );
            }

            if (selectedReport == null) {
              return const ReportDetailEmptyState();
            }

            return ReportDetailBody(
              report: selectedReport,
              onEnableNotifications: _showNotificationsEnabledSnackBar,
            );
          },
        ),
      ),
    );
  }
}

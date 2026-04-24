import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Export buttons for Excel and PDF.
class ExportSection extends StatelessWidget {
  const ExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<
        AnalyticsViewModel,
        ({
          AnalyticsViewState exportState,
          String? exportError,
          String? lastExportedPath,
          String? exportType,
        })>(
      (vm) => (
        exportState: vm.exportState,
        exportError: vm.exportError,
        lastExportedPath: vm.lastExportedPath,
        exportType: vm.exportType,
      ),
    );
    final analyticsViewModel = context.read<AnalyticsViewModel>();
    final isLoading = state.exportState == AnalyticsViewState.loading;

    // Show snackbar on export error.
    if (state.exportState == AnalyticsViewState.error &&
        state.exportError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.exportError!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        analyticsViewModel.clearExportState();
      });
    }

    // Show snackbar on export success.
    if (state.exportState == AnalyticsViewState.success &&
        state.lastExportedPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xuất file thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        analyticsViewModel.clearExportState();
      });
    }

    final isLoadingExcel = isLoading && state.exportType == 'excel';
    final isLoadingPdf = isLoading && state.exportType == 'pdf';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : analyticsViewModel.exportExcel,
            icon: isLoadingExcel
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF217346),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : analyticsViewModel.exportPdf,
            icon: isLoadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

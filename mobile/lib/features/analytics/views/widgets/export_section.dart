import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Export buttons for Excel and PDF.
class ExportSection extends StatelessWidget {
  final AnalyticsViewModel vm;

  const ExportSection({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isLoading = vm.exportState == AnalyticsViewState.loading;

    // Show snackbar on export error.
    if (vm.exportState == AnalyticsViewState.error && vm.exportError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.exportError!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        vm.clearExportState();
      });
    }

    // Show snackbar on export success.
    if (vm.exportState == AnalyticsViewState.success &&
        vm.lastExportedPath != null) {
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
        vm.clearExportState();
      });
    }

    final isLoadingExcel = isLoading && vm.exportType == 'excel';
    final isLoadingPdf = isLoading && vm.exportType == 'pdf';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => vm.exportExcel(),
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
            onPressed: isLoading ? null : () => vm.exportPdf(),
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

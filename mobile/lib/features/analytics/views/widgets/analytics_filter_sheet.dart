import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reports/models/incident_category.dart';
import '../../../reports/services/category_service.dart';
import '../../models/analytics_filter.dart';
import '../../viewmodels/analytics_view_model.dart';

/// Filter bottom sheet for the analytics dashboard.
class AnalyticsFilterSheet extends StatefulWidget {
  final AnalyticsFilter currentFilter;
  final CategoryService categoryService;

  const AnalyticsFilterSheet({
    super.key,
    required this.currentFilter,
    required this.categoryService,
  });

  @override
  State<AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  late String? _from;
  late String? _to;
  late int? _categoryId;
  late String? _priority;

  List<IncidentCategory> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _from = widget.currentFilter.from;
    _to = widget.currentFilter.to;
    _categoryId = widget.currentFilter.categoryId;
    _priority = widget.currentFilter.priority;

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await widget.categoryService.getCategories();
    } catch (_) {}
    if (mounted) setState(() => _loadingCategories = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Từ ngày',
                      value: _from,
                      onPicked: (d) => setState(() => _from = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Đến ngày',
                      value: _to,
                      onPicked: (d) => setState(() => _to = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    ..._categories.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              const SizedBox(height: 16),

              // Priority dropdown
              DropdownButtonFormField<String?>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(
                      value: 'critical', child: Text('Nghiêm trọng')),
                  DropdownMenuItem(value: 'high', child: Text('Cao')),
                  DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                  DropdownMenuItem(value: 'low', child: Text('Thấp')),
                ],
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final vm = context.read<AnalyticsViewModel>();
                        vm.resetFilter();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final vm = context.read<AnalyticsViewModel>();
                        vm.applyFilter(AnalyticsFilter(
                          from: _from,
                          to: _to,
                          categoryId: _categoryId,
                          priority: _priority,
                        ));
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date Field Helper ───────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: hasValue
              ? DateTime.tryParse(value!) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          final formatted =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          onPicked(formatted);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: hasValue
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 17),
                  onPressed: () => onPicked(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 17),
        ),
        isEmpty: !hasValue,
        child: Text(
          hasValue ? value! : '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasValue ? AppColors.textPrimary : AppColors.textHint,
              ),
        ),
      ),
    );
  }
}

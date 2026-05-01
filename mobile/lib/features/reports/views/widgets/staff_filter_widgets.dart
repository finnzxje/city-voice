import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Styled dropdown for filters on dashboards.
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          isExpanded: true,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('Tất cả $label',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Small button to clear all active filters.
class ClearFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const ClearFilterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(Icons.filter_alt_off_rounded,
            size: 20, color: AppColors.error),
      ),
    );
  }
}

/// Pagination arrow button.
class PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const PaginationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: enabled ? AppColors.border : AppColors.divider),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textHint),
      ),
    );
  }
}

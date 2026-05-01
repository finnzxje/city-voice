import 'package:flutter/material.dart';

/// Stat card used on the citizen dashboard (tappable status filter).
class StatusStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? iconColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            Text(
              count.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// CityVoice colour palette — a modern civic design system.
///
/// Primary: Teal-blue gradient conveying trust and civic responsibility.
/// Accent: Warm amber/orange for attention & CTA elements.
/// Semantic: Status-specific colours for the report lifecycle.
class AppColors {
  AppColors._();

  // ── Primary Palette ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D6E6E); // deep teal
  static const Color primaryLight = Color(0xFF4DB6AC); // softer teal
  static const Color primaryDark = Color(0xFF004D40); // rich dark teal

  // ── Accent / CTA ──────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF8F00); // warm amber
  static const Color accentLight = Color(0xFFFFB74D);

  // ── Neutral Palette ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF5F6B7A);
  static const Color textHint = Color(0xFF9DA5B4);
  static const Color border = Color(0xFFE2E6ED);
  static const Color divider = Color(0xFFEEF0F4);

  // ── Dark-mode surfaces ─────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2C);
  static const Color darkSurfaceVariant = Color(0xFF2A2A3C);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFFA0A4B8);
  static const Color darkBorder = Color(0xFF2E2E40);

  // ── Semantic / Status Colours ──────────────────────────────────────────────
  /// `newly_received` — waiting for review
  static const Color statusNew = Color(0xFF2196F3); // blue
  static const Color statusNewBg = Color(0xFFE3F2FD);

  /// `in_progress` — being worked on
  static const Color statusInProgress = Color(0xFFFFA726); // amber
  static const Color statusInProgressBg = Color(0xFFFFF3E0);

  /// `resolved` — fixed
  static const Color statusResolved = Color(0xFF66BB6A); // green
  static const Color statusResolvedBg = Color(0xFFE8F5E9);

  /// `rejected` — inauthentic / rejected
  static const Color statusRejected = Color(0xFFEF5350); // red
  static const Color statusRejectedBg = Color(0xFFFFEBEE);

  // ── Priority Colours ───────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF94A3B8); // Grey
  static const Color priorityMedium = Color(0xFFD97706); // Amber
  static const Color priorityHigh = Color(0xFFEA580C); // Orange
  static const Color priorityCritical = Color(0xFFDC2626); // Red

  // ── Utility ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Status Helpers ─────────────────────────────────────────────────────────
  /// Returns the foreground colour for a given report status string.
  static Color statusColor(String status) {
    return switch (status) {
      'newly_received' => statusNew,
      'in_progress' => statusInProgress,
      'resolved' => statusResolved,
      'rejected' => statusRejected,
      _ => textSecondary,
    };
  }

  /// Returns the soft background colour for a given report status string.
  static Color statusBackgroundColor(String status) {
    return switch (status) {
      'newly_received' => statusNewBg,
      'in_progress' => statusInProgressBg,
      'resolved' => statusResolvedBg,
      'rejected' => statusRejectedBg,
      _ => surfaceVariant,
    };
  }

  /// Returns the colour for a given priority level string.
  static Color priorityColor(String? priority) {
    return switch (priority) {
      'low' => priorityLow,
      'medium' => priorityMedium,
      'high' => priorityHigh,
      'critical' => priorityCritical,
      _ => textHint,
    };
  }
}

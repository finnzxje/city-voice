import 'package:city_voice/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/report_view_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Setup entrance animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadReportDetail(widget.reportId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<ReportViewModel>(
          builder: (context, vm, _) {
            // ── Loading State ───────────────────────────────────
            if (vm.isLoading) {
              return const _LoadingView();
            }

            // ── Error State ─────────────────────────────────────
            if (vm.errorMessage != null && vm.selectedReport == null) {
              return _ErrorView(
                message: vm.errorMessage!,
                onRetry: () => vm.loadReportDetail(widget.reportId),
              );
            }

            final report = vm.selectedReport;
            if (report == null) {
              return const _EmptyView();
            }

            // Trigger animation once data is ready
            _animController.forward();

            final statusColor = AppColors.statusColor(report.currentStatus);
            final statusBg =
                AppColors.statusBackgroundColor(report.currentStatus);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Hero Image App Bar ──────────────────────────
                _HeroAppBar(
                  imageUrl: report.incidentImageUrl,
                  statusLabel: report.statusLabel,
                  statusColor: statusColor,
                  statusBg: statusBg,
                ),

                // ── Main Content ────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _ContentSheet(
                        report: report,
                        theme: theme,
                        isDark: isDark,
                        statusColor: statusColor,
                        statusBg: statusBg,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero App Bar with full-bleed image
// ─────────────────────────────────────────────────────────────────────────────
class _HeroAppBar extends StatelessWidget {
  final String? imageUrl;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;

  const _HeroAppBar({
    required this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.black,
      // Custom back button with frosted circle
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _GlassButton(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Incident photo
            if (imageUrl != null)
              Image.network(
                Utils.getSafeUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PlaceholderHero(),
              )
            else
              const _PlaceholderHero(),

            // Multi-stop gradient for legibility
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x00000000),
                    Color(0x99000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Bottom status pill pinned to lower-left
            Positioned(
              left: 20,
              bottom: 32,
              child: _StatusPill(
                label: statusLabel,
                color: statusColor,
                background: statusBg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White rounded sheet that slides over the hero image
// ─────────────────────────────────────────────────────────────────────────────
class _ContentSheet extends StatelessWidget {
  final dynamic report; // your Report model
  final ThemeData theme;
  final bool isDark;
  final Color statusColor;
  final Color statusBg;

  const _ContentSheet({
    required this.report,
    required this.theme,
    required this.isDark,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Overlap the hero image slightly
      transform: Matrix4.translationValues(0, -28, 0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Category chip ─────────────────────────────
            _CategoryChip(label: report.categoryName),
            const SizedBox(height: 16),

            // ── Report title ──────────────────────────────
            Text(
              report.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),

            // ── Description ───────────────────────────────
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                report.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.65,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 36),

            // ── Section: General Info ─────────────────────
            _SectionLabel(label: 'Thông tin chung'),
            const SizedBox(height: 14),
            _InfoCard(report: report, theme: theme, isDark: isDark),

            // ── Section: Resolution photo ─────────────────
            if (report.resolutionImageUrl != null) ...[
              const SizedBox(height: 36),
              _SectionLabel(label: 'Ảnh xác nhận hoàn thành'),
              const SizedBox(height: 14),
              _ResolutionImage(url: report.resolutionImageUrl!),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card — grouped detail rows
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final dynamic report;
  final ThemeData theme;
  final bool isDark;

  const _InfoCard({
    required this.report,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow(
        icon: Icons.location_on_rounded,
        iconColor: const Color(0xFFEF5350),
        label: 'Vị trí',
        value:
            '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
        subtitle: report.administrativeZoneName,
      ),
      if (report.priority != null)
        _InfoRow(
          icon: Icons.flag_rounded,
          iconColor: AppColors.priorityColor(report.priority),
          label: 'Mức ưu tiên',
          value: report.priorityLabel ?? report.priority!,
          valueColor: AppColors.priorityColor(report.priority),
        ),
      if (report.assignedToName != null)
        _InfoRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF42A5F5),
          label: 'Phụ trách',
          value: report.assignedToName!,
        ),
      _InfoRow(
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF66BB6A),
        label: 'Ngày gửi',
        value: Utils.formatDateTime(report.createdAt),
      ),
      if (report.resolvedAt != null)
        _InfoRow(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          label: 'Ngày giải quyết',
          value: Utils.formatDateTime(report.resolvedAt!),
          valueColor: AppColors.success,
          isLast: true,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildRow(context, rows[i], theme, isDark),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05),
                indent: 60,
                endIndent: 20,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, _InfoRow row, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: row.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, size: 18, color: row.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: row.valueColor ?? theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (row.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass circular button used in the app bar
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: child,
      ),
    );
  }
}

/// Colored status pill shown over the hero image
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small pulsing dot indicator
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted category chip below the title
class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bold section label with a left accent bar
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/// Resolution confirmation image with rounded corners
class _ResolutionImage extends StatelessWidget {
  final String url;

  const _ResolutionImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PlaceholderHero(height: 220),
      ),
    );
  }
}

/// Placeholder shown when image fails to load
class _PlaceholderHero extends StatelessWidget {
  final double? height;

  const _PlaceholderHero({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 52,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen states
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Không tìm thấy báo cáo.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model for info card rows
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.isLast = false,
  });
}

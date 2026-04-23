import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_cached_network_image.dart';
import '../../../../core/utils/app_map_tile_layer.dart';
import '../../../../core/utils/utils.dart';
import '../../models/report.dart';
import '../widgets/timeline_step.dart';
import 'report_detail_presenter.dart';

const _reportDetailPrimaryBlue = Color(0xFF2563EB);
const _reportDetailActionBlue = Color(0xFF1D4ED8);
const _reportDetailSurfaceTint = Color(0xFFEFF6FF);
const _reportDetailPlaceholderColor = Color(0xFF94A3B8);

class ReportDetailBody extends StatelessWidget {
  const ReportDetailBody({
    super.key,
    required this.report,
    required this.onEnableNotifications,
  });

  final Report report;
  final VoidCallback onEnableNotifications;

  @override
  Widget build(BuildContext context) {
    final presenter = ReportDetailPresenter(report);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        ReportDetailHeroImage(report: report),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                ReportDetailCategoryRow(presenter: presenter),
                const SizedBox(height: 24),
                const _ReportDetailSectionLabel(text: 'Mô tả'),
                const SizedBox(height: 10),
                Text(
                  presenter.descriptionText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                ReportDetailLocationCard(
                  report: report,
                  presenter: presenter,
                ),
                const SizedBox(height: 32),
                Text(
                  'Tiến trình xử lý',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 20),
                ReportDetailTimelineSection(items: presenter.timelineItems),
                const SizedBox(height: 32),
                ReportDetailNotificationButton(
                  onPressed: onEnableNotifications,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    presenter.bottomStatusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
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
}

class ReportDetailHeroImage extends StatelessWidget {
  const ReportDetailHeroImage({
    super.key,
    required this.report,
  });

  final Report report;

  @override
  Widget build(BuildContext context) {
    final imageUrl = report.incidentImageUrl;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: AppCachedNetworkImage(
        imageUrl: Utils.getSafeUrl(imageUrl),
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
        memCacheWidth: 1200,
        previewMemCacheWidth: 600,
        placeholder: const _ReportDetailPlaceholderHero(),
        errorWidget: const _ReportDetailPlaceholderHero(),
      ),
    );
  }
}

class ReportDetailCategoryRow extends StatelessWidget {
  const ReportDetailCategoryRow({
    super.key,
    required this.presenter,
  });

  final ReportDetailPresenter presenter;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.location_on_outlined,
            size: 18,
            color: _reportDetailPrimaryBlue,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                presenter.categoryName,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                presenter.createdDateText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
}

class ReportDetailLocationCard extends StatelessWidget {
  const ReportDetailLocationCard({
    super.key,
    required this.report,
    required this.presenter,
  });

  final Report report;
  final ReportDetailPresenter presenter;

  @override
  Widget build(BuildContext context) {
    final markerLocation = LatLng(report.latitude, report.longitude);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _reportDetailSurfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: markerLocation,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  const AppMapTileLayer(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: markerLocation,
                        width: 30,
                        height: 30,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presenter.locationStatusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: presenter.locationStatusColor,
                    letterSpacing: 0.8,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  presenter.administrativeZoneName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  presenter.coordinatesText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportDetailTimelineSection extends StatelessWidget {
  const ReportDetailTimelineSection({
    super.key,
    required this.items,
  });

  final List<ReportDetailTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => TimelineStep(
              title: item.title,
              date: item.date,
              fallbackSubtitle: item.fallbackSubtitle,
              nodeStyle: item.nodeStyle,
              lineColor: item.lineColor,
              isLast: item.isLast,
              isResolvedNode: item.isResolvedNode,
              isCurrent: item.isCurrent,
            ),
          )
          .toList(),
    );
  }
}

class ReportDetailNotificationButton extends StatelessWidget {
  const ReportDetailNotificationButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.notifications_active_outlined,
          size: 20,
        ),
        label: const Text(
          'Nhận thông báo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _reportDetailActionBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class ReportDetailErrorState extends StatelessWidget {
  const ReportDetailErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.error),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class ReportDetailEmptyState extends StatelessWidget {
  const ReportDetailEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Không tìm thấy phản ánh'),
    );
  }
}

class _ReportDetailSectionLabel extends StatelessWidget {
  const _ReportDetailSectionLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.textHint,
      ),
    );
  }
}

class _ReportDetailPlaceholderHero extends StatelessWidget {
  const _ReportDetailPlaceholderHero();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _reportDetailPlaceholderColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}

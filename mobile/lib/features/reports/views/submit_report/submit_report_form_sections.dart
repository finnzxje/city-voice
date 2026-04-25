import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/incident_category.dart';
import 'submit_report_draft.dart';

const _submitPrimaryColor = Color(0xFF2563EB);
const _submitTitleColor = Color(0xFF0F172A);
const _submitLabelColor = Color(0xFF334155);
const _submitHintColor = Color(0xFF94A3B8);
const _submitSecondaryTextColor = Color(0xFF64748B);
const _submitLightSurfaceColor = Color(0xFFF1F5F9);
const _submitFieldSurfaceColor = Color(0xFFE2E8F0);

InputDecoration buildSubmitReportInputDecoration({
  required String hintText,
}) {
  final borderRadius = BorderRadius.circular(12);

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _submitHintColor,
      fontSize: 15,
    ),
    filled: true,
    fillColor: _submitFieldSurfaceColor.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(
        color: _submitPrimaryColor,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(
        color: Colors.red,
        width: 1,
      ),
    ),
  );
}

Future<void> showSubmitReportImageSourcePicker(
  BuildContext context, {
  required VoidCallback onPickFromCamera,
  required VoidCallback onPickFromGallery,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: _submitPrimaryColor,
              ),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(sheetContext);
                onPickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _submitPrimaryColor,
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(sheetContext);
                onPickFromGallery();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showSubmitReportCategoryPicker(
  BuildContext context, {
  required List<IncidentCategory> categories,
  required IncidentCategory? selectedCategory,
  required ValueChanged<IncidentCategory> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Chọn danh mục sự cố',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _submitTitleColor,
              ),
            ),
          ),
          const Divider(height: 1, color: _submitFieldSurfaceColor),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory?.id == category.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? _submitPrimaryColor : _submitLabelColor,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: _submitPrimaryColor,
                        )
                      : null,
                  onTap: () {
                    onSelected(category);
                    Navigator.pop(sheetContext);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

class SubmitReportSectionLabel extends StatelessWidget {
  const SubmitReportSectionLabel({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 20,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: _submitLabelColor,
        ),
      ),
    );
  }
}

class SubmitReportImageSection extends StatelessWidget {
  const SubmitReportImageSection({
    super.key,
    required this.imageFile,
    required this.onTap,
  });

  final File? imageFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          image: imageFile != null
              ? DecorationImage(
                  image: FileImage(imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 40,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nhấn để chọn ảnh sự cố *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: onTap,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class SubmitReportCategoryField extends StatelessWidget {
  const SubmitReportCategoryField({
    super.key,
    required this.selectedCategory,
    required this.onTap,
  });

  final IncidentCategory? selectedCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCategory = selectedCategory != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: _submitFieldSurfaceColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedCategory?.name ?? 'Chọn loại sự cố...',
              style: TextStyle(
                color: hasCategory ? _submitTitleColor : _submitHintColor,
                fontSize: 15,
                fontWeight: hasCategory ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _submitSecondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitReportLocationCard extends StatelessWidget {
  const SubmitReportLocationCard({
    super.key,
    required this.locationState,
    required this.onTap,
    required this.onRefreshLocation,
  });

  final SubmitReportLocationState locationState;
  final VoidCallback onTap;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final latitude = locationState.latitude;
    final longitude = locationState.longitude;
    final hasCoordinates = latitude != null && longitude != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (locationState.isLocating)
                      const Center(
                        child: CircularProgressIndicator(
                          color: _submitPrimaryColor,
                        ),
                      )
                    else if (hasCoordinates)
                      _LocationPreviewMap(
                        latitude: latitude,
                        longitude: longitude,
                      )
                    else
                      Container(
                        color: _submitFieldSurfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.location_off_outlined,
                            size: 40,
                            color: _submitHintColor,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Chạm để điều chỉnh vị trí',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _submitLightSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.near_me,
                    color: _submitSecondaryTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationState.displayTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: locationState.errorMessage != null
                              ? Colors.red
                              : _submitTitleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationState.displaySubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _submitSecondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed:
                        locationState.isLocating ? null : onRefreshLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    color: _submitPrimaryColor,
                    tooltip: 'Lấy lại vị trí GPS',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
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

class SubmitReportSubmitButton extends StatelessWidget {
  const SubmitReportSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _submitPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gửi báo cáo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LocationPreviewMap extends StatelessWidget {
  const _LocationPreviewMap({
    required this.latitude,
    required this.longitude,
  });

  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final currentLatitude = latitude;
    final currentLongitude = longitude;
    if (currentLatitude == null || currentLongitude == null) {
      return const SizedBox.shrink();
    }

    final markerLocation = LatLng(currentLatitude, currentLongitude);

    return FlutterMap(
      key: ValueKey('$currentLatitude-$currentLongitude'),
      options: MapOptions(
        initialCenter: markerLocation,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cityvoice',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: markerLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

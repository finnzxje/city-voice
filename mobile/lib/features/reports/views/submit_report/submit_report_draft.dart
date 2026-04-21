import 'dart:io';

import 'package:latlong2/latlong.dart';

import '../../models/incident_category.dart';

const Object _errorMessageUnset = Object();
const LatLng _defaultMapLocation = LatLng(10.762622, 106.660172);

final class SubmitReportDraft {
  const SubmitReportDraft({
    this.imageFile,
    this.selectedCategory,
    this.location = const SubmitReportLocationState(),
  });

  final File? imageFile;
  final IncidentCategory? selectedCategory;
  final SubmitReportLocationState location;

  String? get submissionValidationMessage {
    if (imageFile == null) {
      return 'Vui lòng chọn ảnh sự cố.';
    }

    if (!location.hasCoordinates) {
      return 'Chưa xác định được vị trí. Vui lòng thử lại.';
    }

    if (selectedCategory == null) {
      return 'Vui lòng chọn danh mục sự cố.';
    }

    return null;
  }

  SubmitReportDraft copyWith({
    File? imageFile,
    IncidentCategory? selectedCategory,
    SubmitReportLocationState? location,
  }) {
    return SubmitReportDraft(
      imageFile: imageFile ?? this.imageFile,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      location: location ?? this.location,
    );
  }
}

final class SubmitReportLocationState {
  const SubmitReportLocationState({
    this.latitude,
    this.longitude,
    this.isLocating = false,
    this.errorMessage,
  });

  final double? latitude;
  final double? longitude;
  final bool isLocating;
  final String? errorMessage;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get displayTitle {
    if (errorMessage != null) {
      return 'Lỗi vị trí';
    }

    if (isLocating) {
      return 'Đang tìm vị trí...';
    }

    return 'Vị trí hiện tại';
  }

  String get displaySubtitle {
    final currentErrorMessage = errorMessage;
    if (currentErrorMessage != null) {
      return currentErrorMessage;
    }

    final currentLatitude = latitude;
    final currentLongitude = longitude;
    if (currentLatitude == null || currentLongitude == null) {
      return 'Chưa xác định được tọa độ';
    }

    return '${currentLatitude.toStringAsFixed(5)}, ${currentLongitude.toStringAsFixed(5)}';
  }

  LatLng get initialMapLocation {
    final currentLatitude = latitude;
    final currentLongitude = longitude;
    if (currentLatitude == null || currentLongitude == null) {
      return _defaultMapLocation;
    }

    return LatLng(currentLatitude, currentLongitude);
  }

  SubmitReportLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLocating,
    Object? errorMessage = _errorMessageUnset,
  }) {
    return SubmitReportLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocating: isLocating ?? this.isLocating,
      errorMessage: identical(errorMessage, _errorMessageUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

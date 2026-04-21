import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/incident_category.dart';
import 'submit_report_draft.dart';

final class SubmitReportFormController extends ChangeNotifier {
  SubmitReportFormController({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  SubmitReportDraft _draft = const SubmitReportDraft();

  SubmitReportDraft get draft => _draft;

  Future<void> detectLocation() async {
    _updateLocation(
      draft.location.copyWith(
        isLocating: true,
        errorMessage: null,
      ),
    );

    final locationResult = await _resolveCurrentLocation();
    final position = locationResult.position;
    if (position == null) {
      _updateLocation(
        draft.location.copyWith(
          isLocating: false,
          errorMessage: locationResult.errorMessage,
        ),
      );
      return;
    }

    _updateLocation(
      draft.location.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isLocating: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (pickedImage == null) {
      return;
    }

    _draft = draft.copyWith(imageFile: File(pickedImage.path));
    notifyListeners();
  }

  void selectCategory(IncidentCategory category) {
    _draft = draft.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void applyPickedLocation(LatLng location) {
    _updateLocation(
      draft.location.copyWith(
        latitude: location.latitude,
        longitude: location.longitude,
        isLocating: false,
        errorMessage: null,
      ),
    );
  }

  Future<_LocationDetectionResult> _resolveCurrentLocation() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return const _LocationDetectionResult.error(
          'Vui lòng bật dịch vụ vị trí.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const _LocationDetectionResult.error(
            'Quyền vị trí bị từ chối.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const _LocationDetectionResult.error(
          'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return _LocationDetectionResult.success(position);
    } catch (_) {
      return const _LocationDetectionResult.error(
        'Không thể lấy vị trí. Vui lòng thử lại.',
      );
    }
  }

  void _updateLocation(SubmitReportLocationState location) {
    _draft = draft.copyWith(location: location);
    notifyListeners();
  }
}

final class _LocationDetectionResult {
  const _LocationDetectionResult.success(this.position) : errorMessage = null;

  const _LocationDetectionResult.error(this.errorMessage) : position = null;

  final Position? position;
  final String? errorMessage;
}

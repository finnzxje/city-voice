import '../constants/api_constants.dart';

class Utils {
  Utils._();

  static String getSafeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    String formattedUrl =
        rawUrl.replaceAll('http://minio', ApiConstants.localhost);
    return Uri.encodeFull(formattedUrl);
  }

  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared network image wrapper with caching and decode-size controls.
class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.previewMemCacheWidth,
    this.previewMemCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final int? previewMemCacheWidth;
  final int? previewMemCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl;
    final defaultPlaceholder = placeholder ?? const _DefaultImagePlaceholder();
    final effectiveErrorWidget = errorWidget ?? const _DefaultImageError();

    if (resolvedImageUrl == null || resolvedImageUrl.isEmpty) {
      return _wrapStateWidget(effectiveErrorWidget);
    }

    final effectivePlaceholder = _buildEffectivePlaceholder(
      resolvedImageUrl,
      defaultPlaceholder,
      effectiveErrorWidget,
    );

    return CachedNetworkImage(
      imageUrl: resolvedImageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      filterQuality: FilterQuality.low,
      fadeOutDuration: const Duration(milliseconds: 120),
      fadeInDuration: const Duration(milliseconds: 120),
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => _wrapStateWidget(effectivePlaceholder),
      errorWidget: (_, __, ___) => _wrapStateWidget(effectiveErrorWidget),
    );
  }

  Widget _wrapStateWidget(Widget child) {
    if (width == null && height == null) {
      return child;
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildEffectivePlaceholder(
    String resolvedImageUrl,
    Widget defaultPlaceholder,
    Widget effectiveErrorWidget,
  ) {
    final previewWidth = previewMemCacheWidth;
    final previewHeight = previewMemCacheHeight;
    final hasPreview = previewWidth != null || previewHeight != null;

    if (!hasPreview) {
      return defaultPlaceholder;
    }

    if (previewWidth == memCacheWidth && previewHeight == memCacheHeight) {
      return defaultPlaceholder;
    }

    return AppCachedNetworkImage(
      imageUrl: resolvedImageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: previewWidth,
      memCacheHeight: previewHeight,
      placeholder: defaultPlaceholder,
      errorWidget: effectiveErrorWidget,
    );
  }
}

Future<void> precacheAppNetworkImage(
  BuildContext context,
  String? imageUrl, {
  int? memCacheWidth,
  int? memCacheHeight,
  int? maxWidthDiskCache,
  int? maxHeightDiskCache,
}) async {
  if (imageUrl == null || imageUrl.isEmpty) {
    return;
  }

  final provider = CachedNetworkImageProvider(
    imageUrl,
    maxWidth: maxWidthDiskCache,
    maxHeight: maxHeightDiskCache,
  );

  final resizedProvider = ResizeImage.resizeIfNeeded(
    memCacheWidth,
    memCacheHeight,
    provider,
  );

  try {
    await precacheImage(resizedProvider, context);
  } catch (_) {
    // Ignore prefetch failures. Visible image widget still handles loading.
  }
}

class _DefaultImagePlaceholder extends StatelessWidget {
  const _DefaultImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DefaultImageError extends StatelessWidget {
  const _DefaultImageError();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textHint,
          size: 36,
        ),
      ),
    );
  }
}

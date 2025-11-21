import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget that loads images from network with caching
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final String?
  cacheKey; // Stable cache key (e.g., mediaPath) to prevent reloads when URL changes
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration? fadeInDuration;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.cacheKey, // Optional stable cache key
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print removed to reduce noise, can be re-enabled if needed
    // debugPrint('🖼️ CachedImage building with URL: ${imageUrl.substring(0, min(imageUrl.length, 100))}...');

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey ?? imageUrl, // Use stable cache key if provided
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 100),
      fadeOutDuration: const Duration(milliseconds: 100),
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
      placeholder: (context, url) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
      },
      errorWidget: (context, url, error) {
        debugPrint('❌ CachedImage error loading $url: $error');
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[400],
              child: const Icon(Icons.error, color: Colors.white, size: 32),
            );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

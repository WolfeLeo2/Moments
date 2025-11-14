import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget that loads images from network with caching
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🖼️ CachedImage building with URL: ${imageUrl.substring(0, 100)}...',
    );

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: (context, imageProvider) {
        debugPrint(
          '✅ Image loaded successfully: ${imageUrl.substring(0, 100)}...',
        );
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
      placeholder: (context, url) {
        debugPrint('📥 Loading image: ${url.substring(0, 100)}...');
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

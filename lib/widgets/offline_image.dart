import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget that displays either a local file image or a network image
/// Prefers local file if available for offline support
class OfflineImage extends StatelessWidget {
  final String? localPath;
  final String? networkUrl;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OfflineImage({
    super.key,
    this.localPath,
    this.networkUrl,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Prefer local file if it exists
    if (localPath != null) {
      final file = File(localPath!);
      imageWidget = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            // Use local file
            debugPrint('OfflineImage: using local file: ${file.path}');
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              cacheWidth: memCacheWidth,
              cacheHeight: memCacheHeight,
              errorBuilder: (context, error, stack) {
                // Fallback to network if local file is corrupted
                debugPrint(
                  'OfflineImage: local file corrupted, falling back to network: $networkUrl',
                );
                return _buildNetworkImage();
              },
            );
          }
          // File doesn't exist, use network
          debugPrint(
            'OfflineImage: local file not found, using network: $networkUrl',
          );
          return _buildNetworkImage();
        },
      );
    } else {
      // No local path, use network
      debugPrint(
        'OfflineImage: no localPath provided, using network: $networkUrl',
      );
      imageWidget = _buildNetworkImage();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildNetworkImage() {
    if (networkUrl == null || networkUrl!.isEmpty) {
      return errorWidget ?? _defaultError();
    }

    return CachedNetworkImage(
      imageUrl: networkUrl!,
      cacheKey: cacheKey ?? networkUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 100),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _defaultError(),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[400],
      child: const Icon(Icons.error, color: Colors.white, size: 32),
    );
  }
}

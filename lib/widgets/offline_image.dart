import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cache for file existence checks to avoid repeated async calls
class _FileExistenceCache {
  static final Map<String, bool> _cache = {};

  static bool? get(String path) => _cache[path];

  static void set(String path, bool exists) {
    _cache[path] = exists;
  }

  static void invalidate(String path) {
    _cache.remove(path);
  }

  static void clear() {
    _cache.clear();
  }
}

/// Widget that displays either a local file image or a network image
/// Prefers local file if available for offline support
class OfflineImage extends StatefulWidget {
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
  State<OfflineImage> createState() => _OfflineImageState();
}

class _OfflineImageState extends State<OfflineImage> {
  bool? _localFileExists;
  bool _checkedLocal = false;

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  @override
  void didUpdateWidget(OfflineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recheck if localPath changed
    if (widget.localPath != oldWidget.localPath) {
      _checkedLocal = false;
      _localFileExists = null;
      _checkLocalFile();
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.localPath == null) {
      if (mounted) {
        setState(() {
          _localFileExists = false;
          _checkedLocal = true;
        });
      }
      return;
    }

    // Check cache first
    final cached = _FileExistenceCache.get(widget.localPath!);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _localFileExists = cached;
          _checkedLocal = true;
        });
      }
      return;
    }

    // Check file system
    final exists = await File(widget.localPath!).exists();
    _FileExistenceCache.set(widget.localPath!, exists);

    if (mounted) {
      setState(() {
        _localFileExists = exists;
        _checkedLocal = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Show placeholder while checking local file (but only briefly)
    if (!_checkedLocal) {
      // Use a minimal placeholder that won't flash
      imageWidget = _buildNetworkImage();
    } else if (_localFileExists == true && widget.localPath != null) {
      // Use local file
      imageWidget = Image.file(
        File(widget.localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth,
        cacheHeight: widget.memCacheHeight,
        gaplessPlayback: true, // Prevents flash during image changes
        errorBuilder: (context, error, stack) {
          // Invalidate cache and fallback to network if local file is corrupted
          debugPrint(
            '⚠️ OfflineImage: Local file error at ${widget.localPath}: $error',
          );
          _FileExistenceCache.invalidate(widget.localPath!);
          return _buildNetworkImage();
        },
      );
    } else {
      // No local path or doesn't exist, use network
      imageWidget = _buildNetworkImage();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildNetworkImage() {
    if (widget.networkUrl == null || widget.networkUrl!.isEmpty) {
      debugPrint(
        '❌ OfflineImage: No network URL for cacheKey=${widget.cacheKey}',
      );
      return widget.errorWidget ?? _defaultError();
    }

    return CachedNetworkImage(
      imageUrl: widget.networkUrl!,
      cacheKey: widget.cacheKey ?? widget.networkUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: Duration.zero, // No fade to prevent flash
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, url) =>
          widget.placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('❌ OfflineImage: Network error for $url: $error');
        return widget.errorWidget ?? _defaultError();
      },
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
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
      width: widget.width,
      height: widget.height,
      color: Colors.grey[400],
      child: const Icon(Icons.error, color: Colors.white, size: 32),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/avatar_cache_service.dart';
import '../core/providers/providers.dart';

class AvatarImage extends ConsumerWidget {
  const AvatarImage({
    super.key,
    this.avatarUrl,
    this.userId,
    this.size = 40,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.placeholder,
    this.errorWidget,
  });

  final String? avatarUrl;
  final String? userId;
  final double size;
  final BoxFit fit;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarCache = ref.watch(avatarCacheServiceProvider);
    final provider = userId != null
        ? avatarCache.getAvatarImageProviderForUser(userId!)
        : avatarCache.getAvatarImageProvider(avatarUrl);

    final imageWidget = provider != null
        ? Image(
            image: provider,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildError(),
          )
        : _buildPlaceholder();

    final child = shape == BoxShape.circle
        ? ClipOval(child: imageWidget)
        : ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: imageWidget,
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        border: borderColor != null && borderWidth > 0
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: child,
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        const Center(
          child: Icon(
            Icons.person,
            size: 20,
            color: Colors.white,
          ),
        );
  }

  Widget _buildError() {
    return errorWidget ?? _buildPlaceholder();
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/widgets/custom_media_bubble.dart';

class ImageMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMediaBubble(
      isSender: isMe,
      color: isMe ? AppTheme.electricPurple : Colors.white,
      tail: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (message.mediaUrl == null) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported),
      );
    }

    // Calculate aspect ratio from metadata if available
    double? aspectRatio;
    if (message.metadata != null &&
        message.metadata!.containsKey('width') &&
        message.metadata!.containsKey('height')) {
      final width = (message.metadata!['width'] as num).toDouble();
      final height = (message.metadata!['height'] as num).toDouble();
      if (height > 0) {
        aspectRatio = width / height;
      }
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: message.mediaUrl!,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) =>
          Container(color: Colors.grey[200], child: const Icon(Icons.error)),
      fit: BoxFit.cover,
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio, child: imageWidget);
    }

    return SizedBox(width: 200, height: 200, child: imageWidget);
  }
}

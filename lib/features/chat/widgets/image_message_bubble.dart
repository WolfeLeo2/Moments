import 'package:chat_bubbles/chat_bubbles.dart' as cb;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

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
    final status = _statusFromSendStatus(message.sendStatus);

    return cb.BubbleNormalImage(
      id: 'image_${message.id}',
      image: _buildImage(),
      isSender: isMe,
      color: isMe ? AppTheme.primaryBlue : Colors.white,
      tail: true,
      sent: status.sent,
      delivered: status.delivered,
      seen: status.seen,
      timestamp: MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt)),
      messageId: message.id,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    );
  }

  Widget _buildImage() {
    final media = SizedBox(width: 220, height: 260, child: _buildImageInner());
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: media);
  }

  Widget _buildImageInner() {
    if (message.localMediaPath != null &&
        File(message.localMediaPath!).existsSync()) {
      return _buildAspectRatioAwareImage(
        FileImage(File(message.localMediaPath!)),
      );
    }

    if (message.mediaUrl == null) {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    return _buildAspectRatioAwareImage(
      CachedNetworkImageProvider(message.mediaUrl!),
    );
  }

  Widget _buildAspectRatioAwareImage(ImageProvider imageProvider) {
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

    final imageWidget = Image(
      image: imageProvider,
      fit: BoxFit.cover, // IMPORTANT: Cover ensures image fills the tail curves
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicatorM3E());
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.error));
      },
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio, child: imageWidget);
    }

    return SizedBox(width: 200, height: 200, child: imageWidget);
  }

  _MessageStatusFlags _statusFromSendStatus(MessageSendStatus status) {
    switch (status) {
      case MessageSendStatus.read:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: true,
        );
      case MessageSendStatus.delivered:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: false,
        );
      case MessageSendStatus.sent:
        return const _MessageStatusFlags(
          sent: true,
          delivered: false,
          seen: false,
        );
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
      case MessageSendStatus.failed:
        return const _MessageStatusFlags(
          sent: false,
          delivered: false,
          seen: false,
        );
    }
  }
}

class _MessageStatusFlags {
  final bool sent;
  final bool delivered;
  final bool seen;

  const _MessageStatusFlags({
    required this.sent,
    required this.delivered,
    required this.seen,
  });
}

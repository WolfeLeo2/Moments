import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moments/data/models/message.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

// 1. The Widget
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        // 2. The ClipPath uses your specific path logic to cut the image
        child: ClipPath(
          clipper: BubbleClipper(isSender: isMe, tail: true),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
            // We add a background color so the "bubble" shape is visible
            // even while the image is loading or if it has transparency.
            color: Colors.grey[300],
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
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
}

// 3. The Custom Clipper
// This wraps your _getBubblePath logic into a Clipper format
class BubbleClipper extends CustomClipper<Path> {
  final bool isSender;
  final bool tail;

  BubbleClipper({required this.isSender, required this.tail});

  @override
  Path getClip(Size size) {
    // Convert boolean to Alignment to match your existing logic
    final alignment = isSender ? Alignment.topRight : Alignment.topLeft;
    return _getBubblePath(size, alignment, tail);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 4. Your Exact Path Logic (Unchanged)
Path _getBubblePath(Size size, Alignment alignment, bool tail) {
  var h = size.height;
  var w = size.width;
  final double _radius = 10.0;
  var path = Path();

  if (alignment == Alignment.topRight) {
    if (tail) {
      path.moveTo(_radius * 2, 0);
      path.quadraticBezierTo(0, 0, 0, _radius * 1.5);
      path.lineTo(0, h - _radius * 1.5);
      path.quadraticBezierTo(0, h, _radius * 2, h);
      path.lineTo(w - _radius * 3, h);
      path.quadraticBezierTo(
        w - _radius * 1.5,
        h,
        w - _radius * 1.5,
        h - _radius * 0.6,
      );
      path.quadraticBezierTo(w - _radius * 1, h, w, h);
      path.quadraticBezierTo(
        w - _radius * 0.8,
        h,
        w - _radius,
        h - _radius * 1.5,
      );
      path.lineTo(w - _radius, _radius * 1.5);
      path.quadraticBezierTo(w - _radius, 0, w - _radius * 3, 0);
    } else {
      path.moveTo(_radius * 2, 0);
      path.quadraticBezierTo(0, 0, 0, _radius * 1.5);
      path.lineTo(0, h - _radius * 1.5);
      path.quadraticBezierTo(0, h, _radius * 2, h);
      path.lineTo(w - _radius * 3, h);
      path.quadraticBezierTo(w - _radius, h, w - _radius, h - _radius * 1.5);
      path.lineTo(w - _radius, _radius * 1.5);
      path.quadraticBezierTo(w - _radius, 0, w - _radius * 3, 0);
    }
  } else {
    if (tail) {
      path.moveTo(_radius * 3, 0);
      path.quadraticBezierTo(_radius, 0, _radius, _radius * 1.5);
      path.lineTo(_radius, h - _radius * 1.5);
      path.quadraticBezierTo(_radius * .8, h, 0, h);
      path.quadraticBezierTo(_radius * 1, h, _radius * 1.5, h - _radius * 0.6);
      path.quadraticBezierTo(_radius * 1.5, h, _radius * 3, h);
      path.lineTo(w - _radius * 2, h);
      path.quadraticBezierTo(w, h, w, h - _radius * 1.5);
      path.lineTo(w, _radius * 1.5);
      path.quadraticBezierTo(w, 0, w - _radius * 2, 0);
    } else {
      path.moveTo(_radius * 3, 0);
      path.quadraticBezierTo(_radius, 0, _radius, _radius * 1.5);
      path.lineTo(_radius, h - _radius * 1.5);
      path.quadraticBezierTo(_radius, h, _radius * 3, h);
      path.lineTo(w - _radius * 2, h);
      path.quadraticBezierTo(w, h, w, h - _radius * 1.5);
      path.lineTo(w, _radius * 1.5);
      path.quadraticBezierTo(w, 0, w - _radius * 2, 0);
    }
  }
  return path;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:avatar_stack/avatar_stack.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/moment.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../widgets/cached_image.dart';

class PlaceOfPowerDetailPage extends StatefulWidget {
  final String placeTitle;
  final List<Moment> moments;
  final List<String> contributorAvatars;

  const PlaceOfPowerDetailPage({
    super.key,
    required this.placeTitle,
    required this.moments,
    required this.contributorAvatars,
  });

  @override
  State<PlaceOfPowerDetailPage> createState() => _PlaceOfPowerDetailPageState();
}

class _PlaceOfPowerDetailPageState extends State<PlaceOfPowerDetailPage> {
  late final ScrollController _scrollController;
  final Map<String, String> _resolvedImageUrls = {};
  bool _resolvingUrls = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Debug: Check if we have moments to display
    debugPrint(
      'PlaceOfPowerDetailPage initialized with ${widget.moments.length} moments',
    );
    for (var moment in widget.moments) {
      debugPrint('Moment: ${moment.title}, Image URL: ${moment.imageUrl}');
    }

    _prepareImageUrls();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlaceOfPowerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.moments, widget.moments)) {
      _prepareImageUrls();
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    } else {
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
  }

  Future<void> _prepareImageUrls() async {
    if (_resolvingUrls) return;

    _resolvingUrls = true;
    final resolved = <String, String>{};

    try {
      // Collect all media paths that need signed URLs
      final mediaPaths = <String>[];
      for (final moment in widget.moments) {
        if (moment.mediaPath?.isNotEmpty == true) {
          mediaPaths.add(moment.mediaPath!);
        }
      }

      // Batch fetch signed URLs using cache
      final signedUrls = await SignedUrlCache.getSignedUrlsBatch(mediaPaths);

      // Map URLs back to moments
      for (final moment in widget.moments) {
        debugPrint('Processing moment: ${moment.id}');
        debugPrint('  Title: ${moment.title}');
        debugPrint('  media_path: ${moment.mediaPath}');

        String? url;

        // Use media_path with signed URL (new approach)
        if (moment.mediaPath?.isNotEmpty == true) {
          url = signedUrls[moment.mediaPath];
          if (url != null) {
            resolved[moment.id] = url;
            debugPrint('  ✓ Resolved via media_path: $url');
          }
        }

        // Fallback to image_url for old data
        if (url == null && moment.imageUrl?.isNotEmpty == true) {
          resolved[moment.id] = moment.imageUrl!;
          debugPrint('  ✓ Using legacy image_url: ${moment.imageUrl}');
        }

        if (url == null && resolved[moment.id] == null) {
          debugPrint('  ✗ Failed to resolve URL');
        }
      }

      debugPrint(
        'Total resolved URLs: ${resolved.length}/${widget.moments.length}',
      );

      if (mounted) {
        setState(() {
          _resolvedImageUrls
            ..clear()
            ..addAll(resolved);
        });
      }
    } finally {
      _resolvingUrls = false;
    }
  }

  String? _resolveImageUrl(Moment moment) {
    return _resolvedImageUrls[moment.id];
  }

  @override
  Widget build(BuildContext context) {
    // Calculate date range
    if (widget.moments.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            widget.placeTitle.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: Text('No moments to display')),
      );
    }

    final sortedMoments = List<Moment>.from(widget.moments)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstDate = sortedMoments.first.timestamp;
    final lastDate = sortedMoments.last.timestamp;

    final dateRange = _formatDateRange(firstDate, lastDate);
    final locationLabel = widget.moments.first.location;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.placeTitle.toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Centered photo count and date range
            Center(
              child: Text(
                '${widget.moments.length} photos • $dateRange',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Centered avatar stack
            if (widget.contributorAvatars.isNotEmpty)
              Center(
                child: AvatarStack(
                  height: 50,
                  avatars: widget.contributorAvatars
                      .map((url) => NetworkImage(url))
                      .toList(),
                  borderColor: Colors.white,
                  borderWidth: 2,
                ),
              ),

            const SizedBox(height: 32),

            // Animated list of cards that unfold into view
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                itemCount: widget.moments.length,
                itemBuilder: (context, index) {
                  final moment = widget.moments[index];
                  final imageUrl = _resolveImageUrl(moment);

                  debugPrint('Building card $index: imageUrl=$imageUrl');

                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 32),
                    child: _buildMomentCard(moment, imageUrl, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Fixed bottom location bar (like reference image)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundBeige,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.brightYellow,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                locationLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMomentCard(Moment moment, String? imageUrl, int index) {
    return _MomentCard(moment: moment, imageUrl: imageUrl);
  }
}

class _MomentCard extends StatelessWidget {
  final Moment moment;
  final String? imageUrl;

  const _MomentCard({required this.moment, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl?.isNotEmpty ?? false)
                  ? CachedImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: _ImageErrorPlaceholder(
                        message: 'Failed to load\n$imageUrl',
                      ),
                    )
                  : _ImageErrorPlaceholder(
                      message: 'No image URL\nMoment: ${moment.title}',
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (moment.caption?.isNotEmpty == true)
          Text(
            moment.caption!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  final String message;

  const _ImageErrorPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

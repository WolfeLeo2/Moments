import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motor/motor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:avatar_stack/avatar_stack.dart';
import '../../../data/models/moment.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../widgets/cached_image.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Details page showing moments in a carousel with spring animations
class MomentDetailsPage extends StatefulWidget {
  final String locationName;
  final List<Moment> moments;
  final String? heroTag;
  final int initialPage;

  const MomentDetailsPage({
    super.key,
    required this.locationName,
    required this.moments,
    this.heroTag,
    this.initialPage = 0,
  });

  @override
  State<MomentDetailsPage> createState() => _MomentDetailsPageState();
}

class _MomentDetailsPageState extends State<MomentDetailsPage>
    with TickerProviderStateMixin {
  final Map<String, String> _imageUrls = {};
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL

  // Motor spring controllers for each card
  final List<SingleMotionController> _scaleControllers = [];
  final List<SingleMotionController> _opacityControllers = [];
  final List<double> _scales = [];
  final List<double> _opacities = [];

  // Motor spring controllers for header elements
  late SingleMotionController _headerScaleController;
  late SingleMotionController _headerOpacityController;
  double _headerScale = 0.85; // Match carousel initial scale
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadImageUrls();
    _loadUserAvatars();
    _setupHeaderAnimations();
    _setupSpringAnimations();
  }

  void _setupHeaderAnimations() {
    // Header scale animation - start from 0.85 like carousel cards
    _headerScaleController = SingleMotionController(
      vsync: this,
      initialValue: 0.85,
      motion: const MaterialSpringMotion.expressiveSpatialFast(),
    );

    _headerScaleController.addListener(() {
      if (mounted) {
        setState(() {
          _headerScale = _headerScaleController.value;
        });
      }
    });

    // Header opacity animation
    _headerOpacityController = SingleMotionController(
      vsync: this,
      initialValue: 0.0,
      motion: const MaterialSpringMotion.expressiveSpatialFast(),
    );

    _headerOpacityController.addListener(() {
      if (mounted) {
        setState(() {
          _headerOpacity = _headerOpacityController.value.clamp(0.0, 1.0);
        });
      }
    });

    // Animate header first (before cards)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _headerScaleController.animateTo(1.0);
        _headerOpacityController.animateTo(1.0);
      }
    });
  }

  void _setupSpringAnimations() {
    // Create Motor spring animations for each card using Material Design 3 tokens
    for (int i = 0; i < widget.moments.length; i++) {
      // Initialize values
      _scales.add(0.85);
      _opacities.add(0.0);

      // Scale controller with Material expressiveSpatialFast spring
      final scaleController = SingleMotionController(
        vsync: this,
        initialValue: 0.85,
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
      );

      scaleController.addListener(() {
        if (mounted && i < _scales.length) {
          setState(() {
            _scales[i] = scaleController.value;
          });
        }
      });

      // Opacity controller with Material expressiveSpatialFast spring
      final opacityController = SingleMotionController(
        vsync: this,
        initialValue: 0.0,
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
      );

      opacityController.addListener(() {
        if (mounted && i < _opacities.length) {
          setState(() {
            _opacities[i] = opacityController.value.clamp(0.0, 1.0);
          });
        }
      });

      _scaleControllers.add(scaleController);
      _opacityControllers.add(opacityController);

      // Stagger the animations with 50ms delays
      Future.delayed(Duration(milliseconds: 80 + (i * 50)), () {
        if (mounted) {
          scaleController.animateTo(1.0);
          opacityController.animateTo(1.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _headerScaleController.dispose();
    _headerOpacityController.dispose();
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    for (var controller in _opacityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadImageUrls() async {
    final mediaPaths = widget.moments
        .map((m) => m.mediaPath)
        .where((path) => path != null && path.isNotEmpty)
        .cast<String>()
        .toList();

    if (mediaPaths.isEmpty) return;

    final urls = await SignedUrlCache.getSignedUrlsBatch(mediaPaths);

    if (mounted) {
      setState(() {
        for (var i = 0; i < widget.moments.length; i++) {
          final moment = widget.moments[i];
          if (moment.mediaPath != null) {
            final url = urls[moment.mediaPath];
            if (url != null) {
              _imageUrls[moment.id] = url;
            }
          }
        }
      });
    }
  }

  Future<void> _loadUserAvatars() async {
    // Get unique user IDs
    final userIds = widget.moments
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet()
        .toList();

    if (userIds.isEmpty) return;

    try {
      // Fetch user metadata from Supabase auth
      // Note: In production, you'd query a profiles table or admin API
      // For now, we'll check current session and populate what we can
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null && userIds.contains(currentUser.id)) {
        final avatarUrl = currentUser.userMetadata?['avatar_url'] as String?;
        if (avatarUrl != null && mounted) {
          setState(() {
            _userAvatars[currentUser.id] = avatarUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading user avatars: $e');
    }
  }

  String _getDateRange() {
    if (widget.moments.isEmpty) return '';

    final dates = widget.moments.map((m) => m.timestamp).toList()..sort();

    final earliest = dates.first;
    final latest = dates.last;

    if (earliest.year == latest.year &&
        earliest.month == latest.month &&
        earliest.day == latest.day) {
      return _formatDate(earliest);
    }

    return '${_formatDate(earliest)} - ${_formatDate(latest)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  List<String> _getUniqueContributorIds() {
    final Set<String> contributorIds = {};
    for (var moment in widget.moments) {
      if (moment.userId != null) {
        contributorIds.add(moment.userId!);
      }
    }
    return contributorIds.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height for proper sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            // Animated header with spring animation
            Transform.scale(
              scale: _headerScale,
              child: Opacity(
                opacity: _headerOpacity,
                child: Column(
                  children: [
                    // AppBar with back button and centered location
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/Left arrow.svg',
                              width: 34,
                              height: 34,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              widget.locationName.toUpperCase(),
                              style: GoogleFonts.bangers(
                                fontSize: 22,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),

                    // Total count and date range in same line (sentence case)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        '${widget.moments.length} ${widget.moments.length == 1 ? 'moment' : 'moments'}  •  ${_getDateRange()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Avatar stack of contributors
                    if (_getUniqueContributorIds().isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.1,
                            height: 40,
                            child: AvatarStack(
                              height: 40,
                              avatars: _getUniqueContributorIds().take(5).map((
                                userId,
                              ) {
                                final avatarUrl = _userAvatars[userId];
                                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                  return NetworkImage(avatarUrl);
                                }
                                // Fallback to a placeholder image
                                return const NetworkImage(
                                  'https://via.placeholder.com/150',
                                );
                              }).toList(),
                              borderWidth: 2,
                              borderColor: Colors.white,
                              infoWidgetBuilder: (surplus, context) {
                                return Center(
                                  child: Text(
                                    '+$surplus',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Carousel with spring animations using carousel_slider - fixed height
            SizedBox(
              height: availableHeight - 200, // Subtract header/avatar space
              child: CarouselSlider.builder(
                itemCount: widget.moments.length,
                options: CarouselOptions(
                  height: availableHeight - 200,
                  viewportFraction: 0.7, // 70% viewport for nice peek effect
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2, // Subtle scale effect
                  enableInfiniteScroll: false,
                  initialPage: widget.initialPage,
                ),
                itemBuilder: (context, index, realIndex) {
                  final moment = widget.moments[index];
                  final imageUrl = _imageUrls[moment.id];

                  // Get animation values
                  final scale = index < _scales.length ? _scales[index] : 0.85;
                  final opacity = index < _opacities.length
                      ? _opacities[index]
                      : 0.0;

                  // Slight rotation for natural feel
                  final rotation = (((index * 37) % 5) - 2) * 0.5;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: rotation * math.pi / 180,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth:
                                  320, // Slightly larger for better visibility with 0.7 viewport
                              maxHeight: 500,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image card with white border - 4:5 aspect ratio
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 5,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: imageUrl != null
                                          ? CachedImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                // Description below image
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16.0,
                                    left: 8.0,
                                    right: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (moment.caption != null &&
                                          moment.caption!.isNotEmpty)
                                        Text(
                                          moment.caption!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.4,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      else
                                        Text(
                                          moment.title,
                                          style: const TextStyle(
                                            fontFamily: 'BebasNeue',
                                            fontSize: 18,
                                            letterSpacing: 1.2,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(moment.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

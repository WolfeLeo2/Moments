import 'package:flutter/material.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:motor/motor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/moment.dart';
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

class _PlaceOfPowerDetailPageState extends State<PlaceOfPowerDetailPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  // Motor springs for expressive physics
  late MotorController _scaleController;
  late MotorController _opacityController;

  double _scale = 0.8;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _setupMotorControllers();
    _playUnfoldAnimation();
  }

  void _setupMotorControllers() {
    // Create bouncy spring controllers
    _scaleController = MotorController(
      initialValue: 0.8,
      spring: const SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 15.0,
      ),
      onUpdate: (value) {
        if (mounted) {
          setState(() {
            _scale = value;
          });
        }
      },
    );

    _opacityController = MotorController(
      initialValue: 0.0,
      spring: const SpringDescription(
        mass: 1.0,
        stiffness: 120.0,
        damping: 20.0,
      ),
      onUpdate: (value) {
        if (mounted) {
          setState(() {
            _opacity = value.clamp(0.0, 1.0);
          });
        }
      },
    );
  }

  void _playUnfoldAnimation() async {
    // Delay for dramatic effect
    await Future.delayed(const Duration(milliseconds: 100));

    // Animate to final values with bouncy springs
    _scaleController.animateTo(1.0);
    _opacityController.animateTo(1.0);
  }

  void _playFoldAnimation() async {
    // Animate back to initial values
    _scaleController.animateTo(0.8);
    _opacityController.animateTo(0.0);

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _opacityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${_getMonthName(start.month)} ${start.day}, ${start.year}';
    }
    return '${_getMonthName(start.month)} ${start.day} - ${_getMonthName(end.month)} ${end.day}, ${end.year}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moments.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundBeige,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('No moments found')),
      );
    }

    final sortedMoments = List<Moment>.from(widget.moments)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstDate = sortedMoments.first.timestamp;
    final lastDate = sortedMoments.last.timestamp;

    final dateRange = _formatDateRange(firstDate, lastDate);

    return Transform.scale(
      scale: _scale,
      child: Opacity(
        opacity: _opacity,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          appBar: AppBar(
            backgroundColor: AppTheme.backgroundBeige,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () async {
                await _playFoldAnimation();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              widget.placeTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),

              // Photo count and date - centered
              Text(
                '${widget.moments.length} PHOTO${widget.moments.length != 1 ? 'S' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                dateRange,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Contributor avatars - centered
              if (widget.contributorAvatars.isNotEmpty)
                Center(
                  child: AvatarStack(
                    height: 40,
                    avatars: widget.contributorAvatars
                        .map((url) => NetworkImage(url))
                        .toList(),
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),

              const SizedBox(height: 24),

              // Image carousel with peek effect
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.moments.length,
                  itemBuilder: (context, index) {
                    final moment = widget.moments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // Image with 3:4 aspect ratio for that rectangular look
                          Expanded(
                            child: AspectRatio(
                              aspectRatio:
                                  3 / 4, // More rectangular like reference
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
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
                                  child: CachedImage(
                                    imageUrl: moment.imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Caption centered
                          if (moment.caption?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                moment.caption!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Fixed bottom location bar (not scrollable)
          bottomNavigationBar: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.moments.first.location ?? 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Motor Controller implementation
class MotorController {
  final double initialValue;
  final SpringDescription spring;
  final ValueChanged<double> onUpdate;

  late AnimationController _controller;
  late Animation<double> _animation;

  MotorController({
    required this.initialValue,
    required this.spring,
    required this.onUpdate,
  });

  void init(TickerProvider vsync) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );

    _animation = Tween<double>(
      begin: initialValue,
      end: initialValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _animation.addListener(() {
      onUpdate(_animation.value);
    });
  }

  void animateTo(double target) {
    _animation = Tween<double>(
      begin: _animation.value,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _animation.addListener(() {
      onUpdate(_animation.value);
    });

    _controller.reset();
    _controller.forward();
  }

  void dispose() {
    _controller.dispose();
  }
}

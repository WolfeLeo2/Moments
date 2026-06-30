import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/avatar_image.dart';
import '../data/story_repository.dart';
import '../providers/story_providers.dart';
import '../widgets/story_progress_bar.dart';

/// Full-screen story viewer. Handles:
///  – Swipe left/right between users
///  – Tap left/right for prev/next story within a user
///  – Long press to pause
///  – Swipe down to close
///  – Auto-advance with progress bar
class StoryViewerPage extends ConsumerStatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  final List<StoryGroup> storyGroups;
  final int initialGroupIndex;

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _groupPageController;
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;

  late AnimationController _progressController;
  bool _isPaused = false;
  bool _shouldRefreshStories = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _groupPageController = PageController(initialPage: _currentGroupIndex);

    // Find the first unseen story in this group
    final group = widget.storyGroups[_currentGroupIndex];
    _currentStoryIndex = group.stories.indexWhere((s) => !s.isViewed);
    if (_currentStoryIndex < 0) _currentStoryIndex = 0;

    _progressController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _startStoryTimer();
    _markCurrentViewed();
  }

  @override
  void dispose() {
    if (_shouldRefreshStories) {
      ref.read(storiesRefreshSignalProvider.notifier).bump();
    }
    _progressController.dispose();
    _groupPageController.dispose();
    super.dispose();
  }

  StoryGroup get _currentGroup => widget.storyGroups[_currentGroupIndex];
  Story get _currentStory => _currentGroup.stories[_currentStoryIndex];

  void _startStoryTimer() {
    final duration = Duration(milliseconds: _currentStory.durationMs);
    _progressController
      ..reset()
      ..duration = duration
      ..forward();
  }

  void _markCurrentViewed() {
    final story = _currentStory;
    ref.read(storyRepositoryProvider).markViewed(story.id);
    _shouldRefreshStories = true;
  }

  // ── Navigation ────────────────────────────────────────────────

  void _nextStory() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStoryTimer();
      _markCurrentViewed();
    } else {
      _nextGroup();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStoryTimer();
      _markCurrentViewed();
    } else {
      _previousGroup();
    }
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.storyGroups.length - 1) {
      _currentGroupIndex++;
      _currentStoryIndex = 0;
      _groupPageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentViewed();
      setState(() {});
    } else {
      Navigator.pop(context);
    }
  }

  void _previousGroup() {
    if (_currentGroupIndex > 0) {
      _currentGroupIndex--;
      final group = widget.storyGroups[_currentGroupIndex];
      _currentStoryIndex = group.stories.length - 1;
      _groupPageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentViewed();
      setState(() {});
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      HapticService.lightTap();
      _previousStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      HapticService.lightTap();
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    _isPaused = true;
    _progressController.stop();
    setState(() {});
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _isPaused = false;
    _progressController.forward();
    setState(() {});
  }

  void _onGroupPageChanged(int index) {
    _currentGroupIndex = index;
    final group = widget.storyGroups[index];
    _currentStoryIndex = group.stories.indexWhere((s) => !s.isViewed);
    if (_currentStoryIndex < 0) _currentStoryIndex = 0;
    _startStoryTimer();
    _markCurrentViewed();
    setState(() {});
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = _currentGroup;
    final isOwn = group.userId == Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onVerticalDragEnd: (details) {
          // Swipe down to close
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.pop(context);
          }
        },
        child: PageView.builder(
          controller: _groupPageController,
          onPageChanged: _onGroupPageChanged,
          itemCount: widget.storyGroups.length,
          itemBuilder: (context, groupIndex) {
            if (groupIndex != _currentGroupIndex) {
              // Only render the active group's content
              return const SizedBox.shrink();
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Story media ──
                _buildMedia(story),

                // ── Gradient overlays ──
                // Top gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Progress bar + header ──
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) => StoryProgressBar(
                            count: group.stories.length,
                            currentIndex: _currentStoryIndex,
                            progress: _progressController.value,
                          ),
                        ),
                      ),
                      _buildHeader(group, story, isOwn),
                    ],
                  ),
                ),

                // ── Caption overlay ──
                if (story.caption != null && story.caption!.isNotEmpty)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Text(
                      story.caption!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ── Location overlay ──
                if (story.location != null)
                  Positioned(
                    bottom: 56,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          story.location!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Paused indicator ──
                if (_isPaused)
                  const Center(
                    child: Icon(
                      CupertinoIcons.pause_fill,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMedia(Story story) {
    if (story.mediaType == 'photo') {
      return CachedNetworkImage(
        imageUrl: story.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.shade900,
          child: const Center(
            child: Icon(CupertinoIcons.photo, color: Colors.white38, size: 48),
          ),
        ),
      );
    }

    // Video placeholder — Phase 2 will add VideoPlayer
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.play_circle_fill,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StoryGroup group, Story story, bool isOwn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AvatarImage(userId: group.userId, size: 36, borderWidth: 0),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.displayName ?? group.username ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _timeAgo(story.createdAt),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Close button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.xmark,
              color: Colors.white,
              size: 22,
            ),
          ),
          // More menu (own stories: delete; others: report)
          if (isOwn)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showDeleteDialog(story),
              child: const Icon(
                CupertinoIcons.trash,
                color: Colors.white70,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Story story) {
    _progressController.stop();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Story'),
        content: const Text('This story will be removed for everyone.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(storyRepositoryProvider).deleteStory(story.id);
              ref.read(storiesRefreshSignalProvider.notifier).bump();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && !_isPaused) {
        _progressController.forward();
      }
    });
  }
}

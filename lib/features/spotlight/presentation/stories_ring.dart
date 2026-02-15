import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/story_repository.dart';
import '../providers/story_providers.dart';
import '../widgets/story_avatar_ring.dart';
import '../presentation/story_camera_page.dart';
import '../presentation/story_viewer_page.dart';

/// Horizontal story ring shown at the top of the Explore page.
class StoriesRing extends ConsumerWidget {
  const StoriesRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(friendsStoriesProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return storiesAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (groups) {
        final hasOwnStory =
            groups.any((g) => g.userId == currentUserId);

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: groups.length + (hasOwnStory ? 0 : 1),
            itemBuilder: (context, index) {
              // First item: "Add" if user has no story, or user's own story
              if (index == 0 && !hasOwnStory) {
                return _StoryCircle(
                  userId: currentUserId ?? '',
                  label: 'Add',
                  hasUnseen: false,
                  isOwn: true,
                  hasStory: false,
                  onTap: () => _openCamera(context),
                );
              }

              final groupIndex = hasOwnStory ? index : index - 1;
              final group = groups[groupIndex];
              final isOwn = group.userId == currentUserId;

              return _StoryCircle(
                userId: group.userId,
                label: isOwn
                    ? 'Your Story'
                    : _shortName(group.displayName, group.username),
                hasUnseen: group.hasUnseen,
                isOwn: isOwn,
                hasStory: true,
                onTap: () {
                  if (isOwn && group.hasUnseen) {
                    // If own story → open viewer
                    _openViewer(context, groups, groupIndex);
                  } else if (isOwn) {
                    // Own story, all seen → open camera
                    _openCamera(context);
                  } else {
                    _openViewer(context, groups, groupIndex);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  String _shortName(String? displayName, String? username) {
    final name = displayName ?? username ?? 'User';
    // Take first name only
    final parts = name.split(' ');
    return parts.first.length > 8
        ? '${parts.first.substring(0, 7)}…'
        : parts.first;
  }

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const StoryCameraPage()),
    );
  }

  void _openViewer(
    BuildContext context,
    List<StoryGroup> groups,
    int initialGroupIndex,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => StoryViewerPage(
          storyGroups: groups,
          initialGroupIndex: initialGroupIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.userId,
    required this.label,
    required this.hasUnseen,
    required this.isOwn,
    required this.hasStory,
    required this.onTap,
  });

  final String userId;
  final String label;
  final bool hasUnseen;
  final bool isOwn;
  final bool hasStory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoryAvatarRing(
              userId: userId,
              size: 60,
              hasUnseen: hasUnseen,
              isOwn: isOwn,
              hasStory: hasStory,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

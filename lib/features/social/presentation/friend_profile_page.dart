import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';
import '../../chat/presentation/chat_page.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../../widgets/offline_image.dart';
import '../../../widgets/avatar_image.dart';

class FriendProfilePage extends ConsumerStatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatarUrl;

  const FriendProfilePage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  ConsumerState<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends ConsumerState<FriendProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    final animationValue = _tabController.animation?.value ?? 0;
    final newIndex = animationValue.round();
    if (newIndex != _selectedTabIndex) {
      HapticService.selectionClick();
      setState(() => _selectedTabIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(friendProfileProvider(widget.friendId));
    final momentsAsync = ref.watch(momentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ── SliverAppBar with back + actions ──
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppTheme.backgroundBeige,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.back, color: Colors.black87),
              ),
              actions: [_buildMoreButton(), const SizedBox(width: 8)],
            ),
            // ── Avatar + Name + Bio ──
            SliverToBoxAdapter(child: _buildProfileHeader(profileAsync)),
            // ── Stats row ──
            SliverToBoxAdapter(child: _buildStatsRow()),
            // ── Mutual friends ──
            SliverToBoxAdapter(child: _buildMutualFriendsRow()),
            // ── Action buttons ──
            SliverToBoxAdapter(child: _buildActionButtons()),
            // ── Cupertino segmented control ──
            SliverToBoxAdapter(child: _buildSegmentedControl()),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMomentsGrid(momentsAsync),
            _buildMapTab(momentsAsync),
          ],
        ),
      ),
    );
  }

  // ── Profile header (avatar centered, name, username, bio) ─────────────

  Widget _buildProfileHeader(AsyncValue profileAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          // ── Avatar ──
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 96,
                height: 96,
                child: widget.friendAvatarUrl != null
                    ? AvatarImage(
                        avatarUrl: widget.friendAvatarUrl,
                        size: 96,
                        borderWidth: 0,
                        backgroundColor: Colors.grey.shade200,
                        placeholder: _buildAvatarPlaceholder(),
                        errorWidget: _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Name ──
          Text(
            widget.friendName,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          // ── Username ──
          profileAsync.when(
            data: (profile) => profile?.username != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '@${profile!.username}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // ── Bio ──
          profileAsync.when(
            data: (profile) {
              if (profile?.bio != null && profile!.bio!.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    profile.bio!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          widget.friendName[0].toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 18, 40, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final momentsCountAsync = ref.watch(
                userMomentsCountProvider(widget.friendId),
              );
              return _buildStatColumn(
                momentsCountAsync.when(
                  data: (count) => count.toString(),
                  loading: () => '-',
                  error: (_, __) => '0',
                ),
                'Moments',
              );
            },
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Consumer(
            builder: (context, ref, _) {
              final mutualAsync = ref.watch(
                mutualFriendsCountProvider(widget.friendId),
              );
              return _buildStatColumn(
                mutualAsync.when(
                  data: (count) => count.toString(),
                  loading: () => '-',
                  error: (_, __) => '0',
                ),
                'Mutual',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ── Mutual friends avatar row ─────────────────────────────────────────

  Widget _buildMutualFriendsRow() {
    return Consumer(
      builder: (context, ref, _) {
        final mutualAsync = ref.watch(
          mutualFriendsCountProvider(widget.friendId),
        );
        return mutualAsync.when(
          data: (count) {
            if (count <= 0) return const SizedBox(height: 8);
            final displayCount = count.clamp(0, 3);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 26.0 + (displayCount - 1) * 16.0,
                    height: 26,
                    child: Stack(
                      children: List.generate(
                        displayCount,
                        (i) => Positioned(
                          left: i * 16.0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                                Colors.grey.shade600,
                              ][i % 3],
                              border: Border.all(
                                color: AppTheme.backgroundBeige,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.person_fill,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count friend${count == 1 ? '' : 's'} in common',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(height: 8),
          error: (_, __) => const SizedBox(height: 8),
        );
      },
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _openChat,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.chat_bubble_fill,
                        size: 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CupertinoSlidingSegmentedControl ──────────────────────────────────

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedTabIndex,
          backgroundColor: CupertinoColors.systemGrey5,
          thumbColor: CupertinoColors.white,
          padding: const EdgeInsets.all(4),
          onValueChanged: (value) {
            if (value == null) return;
            HapticService.selectionClick();
            setState(() => _selectedTabIndex = value);
            _tabController.animateTo(value);
          },
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.square_grid_2x2,
                    size: 16,
                    color: _selectedTabIndex == 0
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Moments',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _selectedTabIndex == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _selectedTabIndex == 0
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            1: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.map,
                    size: 16,
                    color: _selectedTabIndex == 1
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Map',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _selectedTabIndex == 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _selectedTabIndex == 1
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }

  // ── More button (Cupertino action sheet) ──────────────────────────────

  Widget _buildMoreButton() {
    return IconButton(
      onPressed: _showActionsSheet,
      icon: const Icon(
        CupertinoIcons.ellipsis,
        color: Colors.black87,
        size: 22,
      ),
    );
  }

  void _showActionsSheet() {
    HapticService.lightTap();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showBlockConfirmation();
            },
            isDestructiveAction: true,
            child: const Text('Block User'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRemoveFriendConfirmation();
            },
            isDestructiveAction: true,
            child: const Text('Remove Friend'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Report'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ── Chat ──────────────────────────────────────────────────────────────

  void _openChat() {
    HapticService.lightTap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          friendId: widget.friendId,
          friendName: widget.friendName,
          friendAvatarUrl: widget.friendAvatarUrl,
        ),
      ),
    );
  }

  // ── Block / Remove dialogs (Cupertino style) ──────────────────────────

  void _showBlockConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Block ${widget.friendName}?'),
        content: const Text(
          'They won\'t be able to see your moments or message you.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Remove Friend?'),
        content: Text(
          'You\'ll need to send a new friend request to reconnect with ${widget.friendName}.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final repo = ref.read(socialRepositoryProvider);
              await repo.removeFriend(widget.friendId);
              if (!mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              Navigator.pop(this.context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ── Moments grid ──────────────────────────────────────────────────────

  Widget _buildMomentsGrid(AsyncValue<List<Moment>> momentsAsync) {
    return momentsAsync.when(
      data: (allMoments) {
        final friendMoments = allMoments
            .where((m) => m.userId == widget.friendId && !m.isPrivate)
            .toList();

        if (friendMoments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo_on_rectangle,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No shared moments yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When ${widget.friendName.split(' ').first} shares moments,\nthey\'ll appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: friendMoments.length,
          itemBuilder: (context, index) {
            final moment = friendMoments[index];

            return Material(
              color: Colors.grey[100],
              child: InkWell(
                onTap: () => _navigateToDetails(moment, allMoments),
                child: Consumer(
                  builder: (context, ref, child) {
                    final db = ref.read(appDatabaseProvider);
                    return FutureBuilder<String?>(
                      future: db.getLocalMediaPath(moment.id),
                      builder: (context, snapshot) {
                        return OfflineImage(
                          localPath: snapshot.data,
                          networkUrl: moment.imageUrl,
                          cacheKey: moment.id,
                          fit: BoxFit.cover,
                          errorWidget: Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              color: Colors.grey[300],
                              size: 24,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Failed to load moments',
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
      ),
    );
  }

  /// Navigate to moment details - uses UNFILTERED allMoments to get the full group
  void _navigateToDetails(Moment tappedMoment, List<Moment> allMoments) {
    final groupMoments = _getMomentsInSameGroup(tappedMoment, allMoments);
    final groupIndex = groupMoments.indexWhere((m) => m.id == tappedMoment.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomentDetailsPage(
          moments: groupMoments,
          initialPage: groupIndex >= 0 ? groupIndex : 0,
          locationName: tappedMoment.location.split(',').first.trim(),
          heroTag: 'friend_profile_${tappedMoment.id}',
        ),
      ),
    );
  }

  List<Moment> _getMomentsInSameGroup(Moment moment, List<Moment> allMoments) {
    return allMoments
        .where((m) => m.momentGroupId == moment.momentGroupId)
        .toList();
  }

  // ── Map tab ───────────────────────────────────────────────────────────

  Widget _buildMapTab(AsyncValue<List<Moment>> momentsAsync) {
    return momentsAsync.when(
      data: (allMoments) {
        final friendMoments = allMoments
            .where((m) => m.userId == widget.friendId && !m.isPrivate)
            .toList();

        if (friendMoments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.map, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No locations to show',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        double lat = 0;
        double lng = 0;
        for (var m in friendMoments) {
          lat += m.latitude;
          lng += m.longitude;
        }
        final centerLat = lat / friendMoments.length;
        final centerLng = lng / friendMoments.length;

        return Padding(
          padding: const EdgeInsets.all(10),
          child: _FriendMomentsMap(
            moments: friendMoments,
            centerLatitude: centerLat,
            centerLongitude: centerLng,
            onMomentTap: (moment) => _navigateToDetails(moment, allMoments),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _FriendMomentsMap extends StatefulWidget {
  const _FriendMomentsMap({
    required this.moments,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.onMomentTap,
  });

  final List<Moment> moments;
  final double centerLatitude;
  final double centerLongitude;
  final ValueChanged<Moment> onMomentTap;

  @override
  State<_FriendMomentsMap> createState() => _FriendMomentsMapState();
}

class _FriendMomentsMapState extends State<_FriendMomentsMap> {
  static const String _mapboxAccessToken =
      'pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg';

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _tapListenerAttached = false;
  final Map<String, Moment> _annotationMomentById = {};

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(_mapboxAccessToken);
  }

  @override
  void didUpdateWidget(covariant _FriendMomentsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapboxMap != null && oldWidget.moments != widget.moments) {
      _renderMomentAnnotations();
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    await _renderMomentAnnotations();
  }

  Future<void> _renderMomentAnnotations() async {
    if (_mapboxMap == null) return;

    _annotationManager ??= await _mapboxMap!.annotations
        .createPointAnnotationManager();

    if (!_tapListenerAttached) {
      _annotationManager!.tapEvents(
        onTap: (annotation) {
          final moment = _annotationMomentById[annotation.id];
          if (moment != null) {
            widget.onMomentTap(moment);
          }
        },
      );
      _tapListenerAttached = true;
    }

    await _annotationManager!.deleteAll();
    _annotationMomentById.clear();

    for (final moment in widget.moments) {
      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(moment.longitude, moment.latitude),
          ),
          iconImage: 'marker-15',
          iconSize: 1.5,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );

      _annotationMomentById[annotation.id] = moment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MapWidget(
        key: const ValueKey('friend_profile_mapbox_widget'),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              widget.centerLongitude,
              widget.centerLatitude,
            ),
          ),
          zoom: 12,
        ),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded,
      ),
    );
  }
}

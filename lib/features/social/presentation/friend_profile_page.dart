import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/avatar_cache_service.dart';
import '../../../core/services/moment_storage_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/moment.dart';
import '../../chat/presentation/chat_page.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../map/widgets/stacked_moment_marker.dart';
import '../../../widgets/offline_image.dart';

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
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    // Update selected index based on which tab is more visible during swipe
    final animationValue = _tabController.animation?.value ?? 0;
    final newIndex = animationValue.round();
    if (newIndex != _selectedTabIndex) {
      setState(() => _selectedTabIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(friendProfileProvider(widget.friendId));
    final momentsAsync = ref.watch(momentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.backgroundBeige,
              surfaceTintColor: Colors.transparent,
              leading: _buildBackButton(),
              actions: [_buildMoreButton()],
              title: Text(
                widget.friendName,
                style: GoogleFonts.bangers(
                  fontSize: 24.sp,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(child: _buildProfileHeader(profileAsync)),
            SliverToBoxAdapter(child: _buildSegmentedTabs()),
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

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildTabButton(
              index: 0,
              icon: HugeIcons.strokeRoundedGridView,
              label: 'Moments',
            ),
            _buildTabButton(
              index: 1,
              icon: HugeIcons.strokeRoundedMapsLocation01,
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required dynamic icon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTabIndex = index);
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 18.sp,
                color: isSelected ? Colors.black : Colors.grey[600]!,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Icon(Icons.arrow_back, color: Colors.black, size: 20.sp),
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'block':
              _showBlockConfirmation();
              break;
            case 'remove':
              _showRemoveFriendConfirmation();
              break;
            case 'report':
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'block',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Block User', style: GoogleFonts.inter(color: Colors.red)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Remove Friend',
                  style: GoogleFonts.inter(color: Colors.orange),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.black, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Report', style: GoogleFonts.inter(color: Colors.black)),
              ],
            ),
          ),
        ],
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedMoreHorizontal,
            color: Colors.black,
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AsyncValue<Profile?> profileAsync) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
      child: Column(
        children: [
          _buildAvatarSection(profileAsync),
          SizedBox(height: 16.h),
          _buildNameSection(profileAsync),
          SizedBox(height: 10.h),
          _buildBioSection(profileAsync),
          SizedBox(height: 16.h),
          _buildStatsRow(),
          SizedBox(height: 12.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(AsyncValue<Profile?> profileAsync) {
    return Container(
      width: 90.w,
      height: 90.w,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ClipOval(
        child: widget.friendAvatarUrl != null
            ? Image(
                image: AvatarCacheService().getAvatarImageProvider(
                  widget.friendAvatarUrl,
                )!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppTheme.primaryBlue,
      child: Center(
        child: Text(
          widget.friendName[0].toUpperCase(),
          style: GoogleFonts.bangers(fontSize: 36.sp, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNameSection(AsyncValue<Profile?> profileAsync) {
    return Column(
      children: [
        Text(
          widget.friendName,
          style: GoogleFonts.inter(
            fontSize: 22.sp,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        profileAsync.when(
          data: (profile) => profile?.username != null
              ? Text(
                  '@${profile!.username}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBioSection(AsyncValue<Profile?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        if (profile?.bio != null && profile!.bio!.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final momentsCountAsync = ref.watch(
              userMomentsCountProvider(widget.friendId),
            );
            return _buildStatItem(
              momentsCountAsync.when(
                data: (count) => count.toString(),
                loading: () => '-',
                error: (_, __) => '0',
              ),
              'Moments',
            );
          },
        ),
        Container(
          height: 30.h,
          width: 1,
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          color: Colors.grey[300],
        ),
        Consumer(
          builder: (context, ref, _) {
            final mutualAsync = ref.watch(
              mutualFriendsCountProvider(widget.friendId),
            );
            return _buildStatItem(
              mutualAsync.when(
                data: (count) => count.toString(),
                loading: () => '-',
                error: (_, __) => '0',
              ),
              'Mutual Friends',
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return GestureDetector(
      onTap: () => _openChat(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChat,
              size: 18.sp,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Text(
              'Message',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
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

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Block ${widget.friendName}?',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'They won\'t be able to see your moments or message you.',
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Block', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Remove Friend?',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You\'ll need to send a new friend request to reconnect with ${widget.friendName}.',
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(socialRepositoryProvider);
              await repo.removeFriend(widget.friendId);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsGrid(AsyncValue<List<Moment>> momentsAsync) {
    return momentsAsync.when(
      data: (allMoments) {
        // Filter to show only friend's non-private moments in grid
        final friendMoments = allMoments
            .where((m) => m.userId == widget.friendId && !m.isPrivate)
            .toList();

        if (friendMoments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedImage01,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No shared moments yet',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'When ${widget.friendName.split(' ').first} shares moments,\nthey\'ll appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.w,
            mainAxisSpacing: 4.h,
            childAspectRatio: 1,
          ),
          itemCount: friendMoments.length,
          itemBuilder: (context, index) {
            final moment = friendMoments[index];

            return GestureDetector(
              // KEY FIX: Pass allMoments (unfiltered) so _getMomentsInSameGroup
              // can find ALL moments in the group, including current user's
              onTap: () => _navigateToDetails(moment, allMoments),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: Colors.black.withOpacity(1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: FutureBuilder<String?>(
                    future: MomentStorageService().getLocalMediaPath(moment.id),
                    builder: (context, snapshot) {
                      return OfflineImage(
                        localPath: snapshot.data,
                        networkUrl: moment.imageUrl,
                        cacheKey: moment.id,
                        fit: BoxFit.cover,
                        placeholder: Container(color: Colors.grey[200]),
                        errorWidget: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 24.sp,
                          ),
                        ),
                      );
                    },
                  ),
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
    // Get ALL moments in the same group from the UNFILTERED list
    // This ensures we include the current user's moments in the group too
    final groupMoments = _getMomentsInSameGroup(tappedMoment, allMoments);

    // Find the index of the tapped moment within the group
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

  /// Get moments that belong to the same group as the tapped moment
  List<Moment> _getMomentsInSameGroup(Moment moment, List<Moment> allMoments) {
    if (moment.momentGroupId != null) {
      return allMoments
          .where((m) => m.momentGroupId == moment.momentGroupId)
          .toList();
    }
    return [moment];
  }

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
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation01,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No locations to show',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        double lat = 0, lng = 0;
        for (var m in friendMoments) {
          lat += m.latitude;
          lng += m.longitude;
        }
        final center = LatLng(
          lat / friendMoments.length,
          lng / friendMoments.length,
        );

        return Padding(
          padding: EdgeInsets.all(10.w),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.r),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 12),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/512/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg',
                    userAgentPackageName: 'com.moments.app',
                  ),
                  MarkerLayer(
                    markers: friendMoments
                        .map(
                          (m) => Marker(
                            point: LatLng(m.latitude, m.longitude),
                            width: 60.w,
                            height: 60.h,
                            child: StackedMomentMarker(
                              moments: [m],
                              onTap: () => _navigateToDetails(m, allMoments),
                              heroTag: 'map_marker_${m.id}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}

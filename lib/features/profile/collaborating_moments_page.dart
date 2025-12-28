import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

class CollaboratingMomentsPage extends ConsumerStatefulWidget {
  const CollaboratingMomentsPage({super.key});

  @override
  ConsumerState<CollaboratingMomentsPage> createState() =>
      _CollaboratingMomentsPageState();
}

class _CollaboratingMomentsPageState
    extends ConsumerState<CollaboratingMomentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _collaboratingGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchCollaboratingMoments();
  }

  Future<void> _fetchCollaboratingMoments() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch moment groups where the user is a contributor
      // We join with moment_groups to get details
      // Also fetch the creator's profile to show their avatar
      final response = await Supabase.instance.client
          .from('moment_contributors')
          .select('''
            moment_id, 
            moment_groups(
              id, 
              name, 
              place_name, 
              created_at, 
              created_by,
              profiles:created_by (
                username,
                avatar_url
              ),
              moments (
                image_url
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('role', 'contributor'); // Ensure they are accepted contributors

      if (mounted) {
        setState(() {
          _collaboratingGroups = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching collaborating moments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shared Moments',
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collaboratingGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/cry.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shared moments yet',
                    style: TextStyle(fontSize: 16, color: AppTheme.textDark),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _collaboratingGroups.length,
              itemBuilder: (context, index) {
                final item = _collaboratingGroups[index];
                final group = item['moment_groups'] as Map<String, dynamic>;
                final groupId = group['id'];
                final name = group['name'] ?? 'Untitled Moment';
                final place = group['place_name'] ?? 'Unknown Location';

                // Creator details
                final creator = group['profiles'] as Map<String, dynamic>?;
                final creatorName = creator?['username'] ?? 'Unknown';
                final creatorAvatar = creator?['avatar_url'] as String?;

                // Group Image Logic
                final moments = group['moments'] as List<dynamic>?;
                String? groupImageUrl;
                if (moments != null && moments.isNotEmpty) {
                  // Use the first available image as cover
                  for (final m in moments) {
                    if (m['image_url'] != null) {
                      groupImageUrl = m['image_url'];
                      break;
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadiusGeometry.all(
                        Radius.circular(20.sp),
                      ),
                      side: BorderSide(color: AppTheme.borderBlack, width: 1),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _openMomentDetails(groupId, place),
                    borderRadius: BorderRadius.circular(20.sp),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Left side: Group Icon / Image placeholder
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              image: groupImageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        groupImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: groupImageUrl == null
                                ? Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedUserGroup,
                                      color: AppTheme.primaryBlue,
                                      size: 28,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Middle: Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        place,
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Creator chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundImage: AvatarCacheService()
                                            .getAvatarImageProvider(
                                              creatorAvatar,
                                            ),
                                        backgroundColor: Colors.grey[300],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'by $creatorName',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right: Arrow
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openMomentDetails(String groupId, String placeName) async {
    try {
      // Fetch moments for this group
      final momentsResponse = await Supabase.instance.client
          .from('moments')
          .select('*')
          .eq('moment_group_id', groupId)
          .order('created_at', ascending: false);

      final List<dynamic> data = momentsResponse as List<dynamic>;
      final List<Moment> moments = data
          .map((json) => Moment.fromJson(json))
          .toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MomentDetailsPage(
              locationName: placeName,
              moments: moments,
              initialPage: 0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load moments: $e')));
      }
    }
  }
}

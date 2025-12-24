import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/avatar_cache_service.dart';
import '../../core/providers/moments_providers.dart';
import '../moments/presentation/year_in_review_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    final momentsAsync = ref.watch(momentsStreamProvider);
    final currentYear = DateTime.now().year;

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
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              backgroundImage: AvatarCacheService().getAvatarImageProvider(authService.currentUserPhotoUrl),
              child: authService.currentUserPhotoUrl == null
                  ? Text(
                      (authService.currentUserDisplayName ?? 'U')[0]
                          .toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // User name
            Text(
              authService.currentUserDisplayName ?? 'User',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            // Email
            if (authService.currentUserEmail != null)
              Text(
                authService.currentUserEmail!,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),

            const SizedBox(height: 32),

            // Year in Review Card - Featured!
            momentsAsync.when(
              data: (moments) {
                final yearMoments = moments
                    .where((m) => m.timestamp.year == currentYear)
                    .toList();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => YearInReviewPage(
                          moments: moments,
                          year: currentYear,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: ShapeDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1DB954), Color(0xFF191414)],
                      ),
                      shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(20.sp)),
                      ),
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withValues(alpha:0.6),
                          blurRadius: 50.r,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$currentYear WRAPPED',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 28,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${yearMoments.length} moments this year',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'View Your Year →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1DB954),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 48.sp,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Settings section
            _buildSectionHeader('Settings'),
            SizedBox(height: 12.h),

            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedNotification03,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedLock,
              title: 'Privacy',
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedHelpCircle,
              title: 'Help & Support',
              onTap: () {},
            ),

            SizedBox(height: 24.h),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: ShapeDecoration(
        color: AppTheme.cardWhite,
        shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(12.sp)),
        side: BorderSide(color: AppTheme.borderBlack),
      ),
      ),
      child: ListTile(
        leading: HugeIcon(icon: icon, size: 22.sp, color: Colors.black87),
        title: Text(
          title,
          style: GoogleFonts.rubik(fontSize: 16.sp, color: Colors.black),
        ),

        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadiusGeometry.all(
            Radius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_theme.dart';

import '../../core/providers/moments_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/sync_provider.dart';
import '../../data/repositories/social_repository.dart';
import '../moments/presentation/year_in_review_page.dart';
import 'package:moments/features/profile/collaborating_moments_page.dart';
import 'package:moments/widgets/avatar_image.dart';
import 'package:moments/features/mapv2/presentation/map_style_picker_page.dart';
import 'package:moments/core/services/chat_offline_service.dart';
import 'notification_settings_page.dart';
import 'storage_cache_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final momentsAsync = ref.watch(momentsStreamProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PROFILE',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.black,
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () => _showEditProfileDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
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
                  : AvatarImage(
                      avatarUrl: authService.currentUserPhotoUrl,
                      size: 100,
                      borderWidth: 0,
                      backgroundColor: AppTheme.primaryBlue,
                      placeholder: const SizedBox.shrink(),
                    ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.grey[600],
                ),
              ),

            // Bio
            userProfileAsync.when(
              data: (profile) {
                if (profile?.bio != null && profile!.bio!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'GoogleSansFlex',
                        color: Colors.black87,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // Year in Review Card - Featured! (Only in December)
            if (DateTime.now().month == 12)
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
                          borderRadius: BorderRadiusGeometry.all(
                            Radius.circular(20.sp),
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: const Color(
                              0xFF1DB954,
                            ).withValues(alpha: 0.6),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontFamily: 'GoogleSansFlex',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${yearMoments.length} moments this year',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'GoogleSansFlex',
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontFamily: 'GoogleSansFlex',
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.vibrantGreen,
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

            if (DateTime.now().month == 12) const SizedBox(height: 24),

            // Settings section
            _buildSectionHeader('Settings'),
            SizedBox(height: 12.h),

            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedMapsLocation01,
              title: 'Map Style',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapStylePickerPage(),
                  ),
                );
              },
            ),

            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedUserGroup,
              title: 'Shared Moments',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CollaboratingMomentsPage(),
                  ),
                );
              },
            ),

            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedNotification03,
              title: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedLock,
              title: 'Privacy',
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedDatabase,
              title: 'Storage & Cache',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StorageCachePage(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: HugeIcons.strokeRoundedHelpCircle,
              title: 'Help & Support',
              onTap: () {},
            ),

            // Sync Status tile with error indicator
            Builder(
              builder: (context) {
                final syncStatus = ref.watch(syncStatusProvider);
                final errorCount = ref.watch(syncErrorCountProvider);

                return _buildSyncStatusTile(
                  context: context,
                  ref: ref,
                  syncStatus: syncStatus,
                  errorCount: errorCount,
                );
              },
            ),

            SizedBox(height: 24.h),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  ref.read(chatOfflineServiceProvider).stop();
                  await authService.signOut();

                  // Navigate to LoginPage
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: AppTheme.emergencyRed),
                label: Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontFamily: 'GoogleSansFlex',
                    color: AppTheme.emergencyRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
                  ),
                  side: const BorderSide(color: AppTheme.emergencyRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.read(currentUserProfileProvider);
    final bioController = TextEditingController();
    final phoneController = TextEditingController();

    userProfileAsync.whenData((profile) {
      if (profile?.bio != null) {
        bioController.text = profile!.bio!;
      }
      if (profile?.phoneNumber != null) {
        phoneController.text = profile!.phoneNumber!;
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.bebasNeue(fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+254 7XX XXX XXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repo = ref.read(socialRepositoryProvider);
                await repo.updateCurrentUserProfile(
                  bio: bioController.text,
                  phoneNumber: phoneController.text.trim().isNotEmpty
                      ? phoneController.text.trim()
                      : null,
                );
                ref.invalidate(currentUserProfileProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: 'GoogleSansFlex',
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
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

  Widget _buildSyncStatusTile({
    required BuildContext context,
    required WidgetRef ref,
    required SyncStatus syncStatus,
    required int errorCount,
  }) {
    final hasErrors = syncStatus == SyncStatus.error;

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
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 22.sp,
              color: Colors.black87,
            ),
            if (hasErrors)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$errorCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          'Sync Status',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasErrors)
              Icon(Icons.check_circle, color: Colors.green, size: 18.sp)
            else
              Text(
                '$errorCount issues',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.w500,
                  color: AppTheme.emergencyRed,
                ),
              ),
            SizedBox(width: 8.w),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () => _showSyncStatusDialog(context, ref),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadiusGeometry.all(
            Radius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }

  void _showSyncStatusDialog(BuildContext context, WidgetRef ref) {
    final errors = ref.read(syncStateProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync Status', style: GoogleFonts.bebasNeue(fontSize: 24)),
        content: SizedBox(
          width: double.maxFinite,
          child: errors.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48.sp),
                    SizedBox(height: 16.h),
                    Text(
                      'Everything is synced!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'GoogleSansFlex',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    final error =
                        errors[errors.length - 1 - index]; // Newest first
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.error_outline,
                        color: AppTheme.emergencyRed,
                      ),
                      title: Text(error.source.toUpperCase()),
                      subtitle: Text(
                        error.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'GoogleSansFlex',
                          fontWeight: FontWeight.w500,
                          color: AppTheme.emergencyRed,
                        ),
                      ),
                      trailing: Text(
                        _formatTimeAgo(error.timestamp),
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (errors.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(syncStateProvider.notifier).clearAll();
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

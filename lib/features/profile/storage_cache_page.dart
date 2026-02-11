import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_compress/video_compress.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/cache_manager_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/map_cache_service.dart';

class StorageCachePage extends StatefulWidget {
  const StorageCachePage({super.key});

  @override
  State<StorageCachePage> createState() => _StorageCachePageState();
}

class _StorageCachePageState extends State<StorageCachePage> {
  final CacheManagerService _cacheManager = CacheManagerService();
  CacheSizeReport? _report;
  bool _loading = true;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSizes();
  }

  Future<void> _loadCacheSizes() async {
    setState(() => _loading = true);
    try {
      final report = await _cacheManager.getCacheSizes();
      if (mounted) setState(() => _report = report);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: AppTheme.borderBlack,
            width: AppTheme.borderMedium,
          ),
        ),
        title: Text(
          'Clear All Caches?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        content: Text(
          'This will free up ${_report?.formattedTotal ?? 'cache'} space. '
          'Images and audio will be re-downloaded as needed.',
          style: GoogleFonts.inter(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticService.mediumTap();
    setState(() => _clearing = true);
    await _cacheManager.clearAllCaches();
    await _loadCacheSizes();
    if (mounted) {
      setState(() => _clearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All caches cleared',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.vibrantGreen,
        ),
      );
    }
  }

  Future<void> _clearCategory(
    String label,
    Future<void> Function() clearFn,
  ) async {
    HapticService.lightTap();
    setState(() => _clearing = true);
    await clearFn();
    await _loadCacheSizes();
    if (mounted) {
      setState(() => _clearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label cleared',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.vibrantGreen,
        ),
      );
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
          icon: const Icon(CupertinoIcons.back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Storage & Cache',
          style: GoogleFonts.bebasNeue(
            textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.textDark,
                ),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final report = _report;
    if (report == null) {
      return Center(
        child: Text(
          'Unable to load cache info',
          style: GoogleFonts.inter(color: AppTheme.textGray),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        // Total size card
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.borderBlack,
              width: AppTheme.borderMedium,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(height: 8.h),
              Text(
                report.formattedTotal,
                style: GoogleFonts.bebasNeue(
                  fontSize: 32.sp,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                'Total cache size',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textGray,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _clearing ? null : _clearAll,
                  icon: _clearing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_sweep, size: 18),
                  label: Text(
                    _clearing ? 'Clearing...' : 'Clear All Caches',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralPink,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      side: BorderSide(
                        color: AppTheme.borderBlack,
                        width: AppTheme.borderMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        Text(
          'Cache Breakdown',
          style: GoogleFonts.bebasNeue(
            fontSize: 18.sp,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 8.h),

        // Individual cache tiles
        _buildCacheTile(
          icon: Icons.image_outlined,
          title: 'Images',
          subtitle: 'Cached network images, thumbnails',
          size: report.cachedNetworkImage,
          onClear: () =>
              _clearCategory('Image cache', _cacheManager.clearImageCaches),
        ),
        _buildCacheTile(
          icon: Icons.music_note_outlined,
          title: 'Audio',
          subtitle: 'Music previews, voice messages',
          size: report.justAudioCache + report.chatMediaCache,
          onClear: () =>
              _clearCategory('Audio cache', _cacheManager.clearAudioCaches),
        ),
        _buildCacheTile(
          icon: Icons.map_outlined,
          title: 'Map Tiles',
          subtitle: 'Offline map data',
          size: report.mapCache,
          onClear: () => _clearCategory('Map cache', () async {
            final service = MapCacheService();
            await service.clearCache();
          }),
        ),
        _buildCacheTile(
          icon: Icons.person_outline,
          title: 'Avatars',
          subtitle: 'Profile pictures',
          size: report.avatarCache,
          onClear: () =>
              _clearCategory('Avatar cache', _cacheManager.clearImageCaches),
        ),
        _buildCacheTile(
          icon: Icons.photo_library_outlined,
          title: 'Moment Media',
          subtitle: 'Offline moment photos & videos',
          size: report.momentMediaCache,
          onClear: () => _clearCategory('Moment media cache', () async {
            await _cacheManager.clearAllCaches();
          }),
        ),
        _buildCacheTile(
          icon: Icons.videocam_outlined,
          title: 'Video Compression',
          subtitle: 'Temporary video files',
          size: report.videoCompressCache,
          onClear: () => _clearCategory('Video compression cache', () async {
            await VideoCompress.deleteAllCache();
          }),
        ),
      ],
    );
  }

  Widget _buildCacheTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int size,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderGray, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryBlue),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CacheSizeReport.formatBytes(size),
            style: GoogleFonts.spaceMono(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: size > 50 * 1024 * 1024
                  ? AppTheme.coralPink
                  : AppTheme.textGray,
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _clearing ? null : onClear,
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

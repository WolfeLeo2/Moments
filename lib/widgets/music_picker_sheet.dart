import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/deezer_service.dart';
import 'package:moments/core/services/curated_audio_service.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/data/models/music_data.dart';

/// Bottom sheet with two tabs: "Curated" and "Deezer Search"
/// Returns the selected [MusicData] or null if dismissed.
Future<MusicData?> showMusicPickerSheet(BuildContext context) {
  return showModalBottomSheet<MusicData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicPickerSheet(),
  );
}

class _MusicPickerSheet extends StatefulWidget {
  const _MusicPickerSheet();

  @override
  State<_MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<_MusicPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _curatedSearchController = TextEditingController();
  final _deezerService = DeezerService();
  Timer? _debounce;
  Timer? _curatedDebounce;

  // State
  List<MusicData> _curatedTracks = [];
  List<MusicData> _curatedSearchResults = [];
  bool _searchingCurated = false;
  List<DeezerTrack> _deezerResults = [];
  List<DeezerTrack> _deezerChart = [];
  bool _loadingCurated = true;
  bool _loadingDeezer = false;
  bool _loadingChart = true;

  // Preview playback
  AudioPlayer? _previewPlayer;
  String? _playingUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurated();
    _loadChart();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _curatedSearchController.dispose();
    _deezerService.dispose();
    _debounce?.cancel();
    _curatedDebounce?.cancel();
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadCurated() async {
    final tracks = await CuratedAudioService.listTracks();
    if (mounted) {
      setState(() {
        _curatedTracks = tracks;
        _loadingCurated = false;
      });
    }
  }

  Future<void> _loadChart() async {
    final chart = await _deezerService.getChart(limit: 20);
    if (mounted) {
      setState(() {
        _deezerChart = chart;
        _loadingChart = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _deezerResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchDeezer(query);
    });
  }

  void _onCuratedSearchChanged(String query) {
    _curatedDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _curatedSearchResults = [];
        _searchingCurated = false;
      });
      return;
    }
    setState(() => _searchingCurated = true);
    _curatedDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchCurated(query);
    });
  }

  Future<void> _searchCurated(String query) async {
    final results = await CuratedAudioService.search(query);
    if (mounted) {
      setState(() {
        _curatedSearchResults = results;
        _searchingCurated = false;
      });
    }
  }

  Future<void> _searchDeezer(String query) async {
    setState(() => _loadingDeezer = true);
    final results = await _deezerService.search(query);
    if (mounted) {
      setState(() {
        _deezerResults = results;
        _loadingDeezer = false;
      });
    }
  }

  Future<void> _togglePreview(String url) async {
    HapticService.lightTap();
    _previewPlayer ??= AudioPlayer();

    if (_playingUrl == url) {
      await _previewPlayer!.stop();
      setState(() => _playingUrl = null);
      return;
    }

    try {
      setState(() => _playingUrl = url);
      await _previewPlayer!.setUrl(url);
      _previewPlayer!.play();

      // Auto-stop listener
      _previewPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingUrl = null);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _playingUrl = null);
    }
  }

  void _selectTrack(MusicData data) {
    HapticService.mediumTap();
    _previewPlayer?.stop();
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundBeige,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'ADD MUSIC',
            style: GoogleFonts.bebasNeue(
              fontSize: 24,
              letterSpacing: 1.5,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGray),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textGray,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'My Collection'),
                Tab(text: 'Deezer'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCuratedTab(), _buildDeezerTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedTab() {
    return Column(
      children: [
        // Curated search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _curatedSearchController,
            onChanged: _onCuratedSearchChanged,
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: 'Search your collection...',
              hintStyle: TextStyle(color: AppTheme.textGray),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textGray,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.lavenderPop,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Results
        Expanded(
          child: _searchingCurated || _loadingCurated
              ? const Center(child: CircularProgressIndicator())
              : _curatedSearchController.text.isNotEmpty
              ? _buildCuratedResults(_curatedSearchResults)
              : _buildCuratedResults(_curatedTracks),
        ),
      ],
    );
  }

  Widget _buildCuratedResults(List<MusicData> tracks) {
    if (tracks.isEmpty) {
      final isSearch = _curatedSearchController.text.isNotEmpty;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.library_music_outlined,
              size: 48,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 12),
            Text(
              isSearch ? 'No results found' : 'No curated tracks yet',
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textGray),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 4),
              Text(
                'Add tracks via the admin tools',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textGray.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        return _buildCuratedTrackTile(tracks[index]);
      },
    );
  }

  Widget _buildCuratedTrackTile(MusicData track) {
    final isPlaying = _playingUrl == track.url;

    return GestureDetector(
      onTap: () => _selectTrack(track),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlaying ? AppTheme.primaryBlue : AppTheme.borderGray,
          ),
        ),
        child: Row(
          children: [
            // Music icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.lavenderPop.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: AppTheme.lavenderPop,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Preview button
            GestureDetector(
              onTap: () => _togglePreview(track.url),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: isPlaying ? Colors.white : AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeezerTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: 'Search songs, artists...',
              hintStyle: TextStyle(color: AppTheme.textGray),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textGray,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Results or chart
        Expanded(
          child: _loadingDeezer
              ? const Center(child: CircularProgressIndicator())
              : _searchController.text.isNotEmpty
              ? _buildDeezerList(_deezerResults)
              : _buildDeezerChartList(),
        ),
      ],
    );
  }

  Widget _buildDeezerChartList() {
    if (_loadingChart) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deezerChart.isEmpty) {
      return Center(
        child: Text(
          'Search for a song to get started',
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textGray),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'POPULAR RIGHT NOW',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildDeezerList(_deezerChart)),
      ],
    );
  }

  Widget _buildDeezerList(List<DeezerTrack> tracks) {
    if (tracks.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textGray),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _buildDeezerTrackTile(track);
      },
    );
  }

  Widget _buildDeezerTrackTile(DeezerTrack track) {
    final isPlaying = _playingUrl == track.previewUrl;
    final musicData = track.toMusicData();

    return GestureDetector(
      onTap: () => _selectTrack(musicData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlaying ? AppTheme.coralPink : AppTheme.borderGray,
          ),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.albumArt.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: track.albumArt,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _albumPlaceholder(),
                      errorWidget: (_, __, ___) => _albumPlaceholder(),
                    )
                  : _albumPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artistName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Preview button
            GestureDetector(
              onTap: () => _togglePreview(track.previewUrl),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppTheme.coralPink
                      : AppTheme.coralPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: isPlaying ? Colors.white : AppTheme.coralPink,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppTheme.borderGray,
      child: const Icon(Icons.album, color: AppTheme.textGray, size: 24),
    );
  }
}

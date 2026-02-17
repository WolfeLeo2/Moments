import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:wechat_assets_picker/wechat_assets_picker.dart'
    hide LatLng, RequestType;
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:supercluster/supercluster.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/signed_url_cache.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/auth_service.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/map_state_provider.dart';
import '../../../data/models/moment.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../moments/presentation/add_moment_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../social/presentation/friends_page.dart';
import '../../profile/profile_page.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../widgets/moment_cards_carousel.dart';
import '../widgets/location_label.dart';
import '../../map/utils/map_logic_service.dart';
import '../providers/ghost_mode_provider.dart';
import '../services/ghost_mode_service.dart';
import '../widgets/pulse_layer.dart';
import '../utils/trail_manager.dart';

final _log = AppLogger('MapPageV2');

const String _mapboxAccessToken =
    'pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg';

// ---------------------------------------------------------------------------
// Lightweight data object for each moment fed into supercluster
// ---------------------------------------------------------------------------

class _MomentPoint {
  final String momentId;
  final String userId;
  final double longitude;
  final double latitude;
  final String location;
  final String title;
  final String momentGroupId;
  final String? mediaUrl; // Signed URL or image_url for thumbnail
  final String? thumbnailUrl; // Video thumbnail if applicable
  final String? mediaPath; // Storage path
  final String? localMediaPath; // Local file path
  final String? localThumbnailPath; // Local thumbnail path
  final String mediaType; // 'image' or 'video'

  const _MomentPoint({
    required this.momentId,
    required this.userId,
    required this.longitude,
    required this.latitude,
    required this.location,
    required this.title,
    required this.momentGroupId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaPath,
    this.localMediaPath,
    this.localThumbnailPath,
    this.mediaType = 'image',
  });
}

/// Map page V2 using native Mapbox GL with supercluster-driven
/// avatar PointAnnotations for markers.
///
/// Key design decisions:
/// - Uses `supercluster` Dart package for clustering instead of Mapbox's native
///   GeoJSON source clustering — allows avatar bitmap markers per cluster.
/// - Renders avatar circle bitmaps via `PointAnnotationManager`.
/// - Map viewport drives the bottom carousel cards (not vice versa).
/// - Uses [location] package only for initial camera position; Mapbox handles the puck.
class MapPageV2 extends ConsumerStatefulWidget {
  const MapPageV2({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<MapPageV2> createState() => _MapPageV2State();
}

class _MapPageV2State extends ConsumerState<MapPageV2>
    with WidgetsBindingObserver {
  AuthService get _authService => ref.read(authServiceProvider);

  MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  bool _isStyleLoaded = false;
  LocationData? _currentPosition;

  String _cityName = '';
  double _currentZoom = 14.0;
  Timer? _annotationDebounce;
  Timer? _geocodeDebounce;

  List<Map<String, dynamic>> _visibleGroups = [];
  List<Moment> _allVisibleMoments = [];

  // Supercluster
  // Supercluster
  SuperclusterImmutable<_MomentPoint>? _cluster;
  PointAnnotationManager? _annotationManager;
  final Map<String, Uint8List> _bitmapCache = {};

  // Avatar Image Caching (Non-blocking)
  final Map<String, ui.Image> _loadedAvatars = {};
  final Set<String> _loadingAvatars = {};

  bool _updatingAnnotations = false;
  int _momentsHash = 0;
  int? _lastElementsHash;
  int? _lastZoomStep;
  Position? _lastGroupCenter;
  final Map<int, List<LayerElement<_MomentPoint>>> _elementsByZoom = {};
  final Map<int, String> _boundsKeyByZoom = {};
  late final _AnnotationClickListener _annotationClickListener;

  // Map annotation ID -> Moment/Cluster ID
  final Map<String, String> _annotationMomentIds = {};
  // Track current annotation IDs on the map to enable diffing
  final Set<String> _currentAnnotationIds = {};

  Timer? _locationPollTimer;

  // ── Feature 1: Live Pulse ──
  Offset? _pulseCenter;
  bool _showPulse = false;

  // ── Feature 2: Neon Trails ──
  final TrailManager _trailManager = TrailManager();
  Timer? _trailUpdateTimer;
  static const _trailSourceId = 'neon-trail-source';
  static const _trailLayerId = 'neon-trail-layer';
  static const _trailGlowLayerId = 'neon-trail-glow';

  // (Feature 3: Moment Beams — removed as unnecessary for 2D usage)

  // ── Live Friends (Ghost Mode markers) ──
  PointAnnotationManager? _liveFriendAnnotationManager;
  StreamSubscription<Map<String, LiveFriend>>? _liveFriendsSubscription;
  final Map<String, String> _liveFriendAnnotationIds = {}; // userId -> MapboxID
  final Set<String> _currentLiveFriendIds = {};
  Map<String, LiveFriend> _latestLiveFriends = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapboxOptions.setAccessToken(_mapboxAccessToken);
    _annotationClickListener = _AnnotationClickListener(_onAnnotationTapped);
    // Don't call _initializeLocation here — let Mapbox's puck handle the
    // permission dialog in _onStyleLoaded to avoid duplicate system prompts.
  }

  final Location _location = Location();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _annotationDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _locationPollTimer?.cancel();
    _trailUpdateTimer?.cancel();
    _trailManager.clear();
    _liveFriendsSubscription?.cancel();
    _liveFriendAnnotationManager = null;
    _annotationManager = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location (one-shot for initial camera, not continuous)
  // ---------------------------------------------------------------------------

  /// Enable the Mapbox blue-dot puck. Called from [_onStyleLoaded] so that the
  /// map is guaranteed to exist. Mapbox handles its own permission dialog on
  /// iOS/Android — we no longer call `location.requestPermission()` to avoid
  /// duplicate system dialogs and the puck failing to display.
  Future<void> _enableLocationPuck() async {
    if (_mapboxMap == null) return;
    try {
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: AppTheme.primaryBlue.toARGB32(),
          showAccuracyRing: false,
        ),
      );
      _log.i('Location puck enabled');
    } catch (e) {
      _log.w('Could not enable location puck: $e');
    }
  }

  /// Fetch the device position once (for initial camera fly-to).
  /// Only reads the permission status — never requests it. Mapbox's puck
  /// in [_enableLocationPuck] handles the native permission dialog.
  /// Uses [Location().hasPermission()] which does NOT show a dialog,
  /// then [Location().getLocation()] only if already granted.
  ///
  /// Returns [true] if permission was granted (position obtained or obtainable),
  /// [false] if explicitly denied (caller should stop polling).
  Future<bool> _initializeLocation() async {
    try {
      final permission = await _location.hasPermission();

      // Permanently denied — no point in polling further
      if (permission == PermissionStatus.deniedForever) {
        _log.i('Location permission permanently denied – stop polling');
        return false;
      }

      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        _log.i('Location permission not yet granted – waiting for puck dialog');
        return true; // Still might be granted, keep polling
      }

      // Add timeout to prevent hanging indefinitely
      final loc = await _location.getLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Location fetch timed out');
        },
      );
      if (mounted && loc.latitude != null && loc.longitude != null) {
        setState(() => _currentPosition = loc);
        _flyToUserLocation();
        // ── Feature 2: Feed location into neon trail ──
        _addTrailPoint(loc.latitude!, loc.longitude!);
      }
      return true;
    } catch (e) {
      _log.e('Location init error: $e');
      return true;
    }
  }

  /// Poll for location permission grant after Mapbox's puck dialog.
  /// Checks every 2s up to 15 times (30s) for the user to accept.
  /// Stops early if permission is permanently denied.
  void _startLocationPolling() {
    _locationPollTimer?.cancel();
    if (_currentPosition != null) return;
    int attempts = 0;
    _locationPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      attempts++;
      if (_currentPosition != null || attempts > 15 || !mounted) {
        timer.cancel();
        return;
      }
      final shouldContinue = await _initializeLocation();
      if (!shouldContinue) {
        _log.i('Permission denied permanently, cancelling poll');
        timer.cancel();
      }
    });
  }

  Future<void> _flyToUserLocation() async {
    if (_currentPosition == null || _mapboxMap == null) {
      _log.w('Cannot fly: position or map is null');
      return;
    }
    if (!_isStyleLoaded) {
      _log.w('Cannot fly: Style not loaded yet');
      return;
    }

    _log.i(
      'Flying to user location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
    );

    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude!,
              _currentPosition!.latitude!,
            ),
          ),
          zoom: 14.0,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      _log.e('FlyTo failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Map lifecycle callbacks
  // ---------------------------------------------------------------------------

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _log.i('Map created');

    // LocationComponent is enabled in _initializeLocation after permission
    // is confirmed, to avoid a duplicate system dialog.

    _isMapReady = true;
    if (_currentPosition != null) {
      _flyToUserLocation();
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    _isStyleLoaded = true;
    _log.i('Style loaded');

    if (_mapboxMap == null) return;

    // Enable the blue-dot puck (Mapbox handles its own permission dialog)
    await _enableLocationPuck();

    // Try to read location (succeeds instantly if already granted).
    // If not granted, start polling — the puck dialog will grant access.
    if (_currentPosition == null) {
      await _initializeLocation();
      if (_currentPosition == null) {
        _startLocationPolling();
      }
    } else {
      _flyToUserLocation();
    }

    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    // ignore: deprecated_member_use
    _annotationManager?.addOnPointAnnotationClickListener(
      _annotationClickListener,
    );

    if (_allVisibleMoments.isNotEmpty) {
      _rebuildCluster(_allVisibleMoments);
      await _updateAnnotations();
      _updateVisibleGroups();
    }

    final cameraState = await _mapboxMap!.getCameraState();
    _scheduleViewportUpdate(cameraState);

    // ── Feature 2: Neon Trails — add GeoJSON source + LineLayer ──
    await _setupTrailLayer();

    // (Feature 3: Moment Beams — removed)

    // ── Live Friends — separate annotation manager + stream ──
    _liveFriendAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    // ignore: deprecated_member_use
    _liveFriendAnnotationManager?.addOnPointAnnotationClickListener(
      _AnnotationClickListener(_onLiveFriendTapped),
    );
    final ghostService = ref.read(ghostModeServiceProvider);
    _liveFriendsSubscription = ghostService.liveFriendsStream.listen((friends) {
      if (mounted) {
        _latestLiveFriends = friends;
        _updateLiveFriendAnnotations(friends);
      }
    });
  }

  // =========================================================================
  // Feature 2: Neon Trails — Mapbox Layers
  // =========================================================================

  /// Set up the GeoJSON source and two line layers for the neon trail effect.
  Future<void> _setupTrailLayer() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    // Empty GeoJSON line
    const emptyGeo =
        '{"type":"Feature","geometry":{"type":"LineString","coordinates":[]}}';

    await style.addSource(GeoJsonSource(id: _trailSourceId, data: emptyGeo));

    // Outer glow layer (wider, more transparent)
    await style.addLayer(
      LineLayer(
        id: _trailGlowLayerId,
        sourceId: _trailSourceId,
        lineColor: 0xFF00E5FF, // Cyan neon
        lineWidth: 8.0,
        lineOpacity: 0.3,
        lineBlur: 6.0,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );

    // Inner core layer (thin, bright)
    await style.addLayer(
      LineLayer(
        id: _trailLayerId,
        sourceId: _trailSourceId,
        lineColor: 0xFF00E5FF,
        lineWidth: 3.0,
        lineOpacity: 0.8,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
  }

  /// Push updated trail coordinates to the Mapbox source.
  Future<void> _updateTrailSource() async {
    if (_mapboxMap == null) return;
    final coords = _trailManager.toCoordinates();
    if (coords.length < 2) return;

    final coordsJson = coords.map((c) => '[${c[0]},${c[1]}]').join(',');
    final geojson =
        '{"type":"Feature","geometry":{"type":"LineString","coordinates":[$coordsJson]}}';

    try {
      final source = await _mapboxMap!.style.getSource(_trailSourceId);
      if (source is GeoJsonSource) {
        await _mapboxMap!.style.setStyleSourceProperty(
          _trailSourceId,
          'data',
          geojson,
        );
      }
    } catch (e) {
      _log.e('Error updating trail source: $e');
    }
  }

  /// Feed a location point into the trail and update the map source.
  void _addTrailPoint(double lat, double lng) {
    _trailManager.addPoint(lat, lng);
    _updateTrailSource();
  }

  // =========================================================================
  // (Feature 3: Moment Beams — removed entirely)

  // =========================================================================
  // Feature 1: Live Pulse — UI trigger
  // =========================================================================

  /// Trigger a pulse animation at the given screen position.
  void _triggerPulseAt(Offset screenPoint) {
    setState(() {
      _pulseCenter = screenPoint;
      _showPulse = true;
    });
  }

  bool _isRouteCurrent() {
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? true;
  }

  bool _isValidCamera(CameraState cameraState) {
    final center = cameraState.center.coordinates;
    final lat = center.lat.toDouble();
    final lng = center.lng.toDouble();
    if (lat.isNaN || lng.isNaN) return false;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return false;
    return true;
  }

  Future<void> _onMapIdle(MapIdleEventData data) async {
    if (!mounted || !_isMapReady || !_isStyleLoaded) return;
    if (!_isRouteCurrent()) return;
    if (_mapboxMap == null) return;
    final cameraState = await _mapboxMap!.getCameraState();
    if (!_isValidCamera(cameraState)) return;
    _currentZoom = cameraState.zoom;
    ref
        .read(mapUiStateProvider.notifier)
        .setCamera(
          MapCameraState(
            latitude: cameraState.center.coordinates.lat.toDouble(),
            longitude: cameraState.center.coordinates.lng.toDouble(),
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: cameraState.pitch,
          ),
        );
    _scheduleViewportUpdate(cameraState);
  }

  void _onCameraChanged(CameraChangedEventData data) {
    if (!mounted || !_isMapReady || !_isStyleLoaded) return;
    if (!_isRouteCurrent()) return;
    final cameraState = data.cameraState;
    if (!_isValidCamera(cameraState)) return;
    _currentZoom = cameraState.zoom;
    // (Pitch tracking for beams — removed)
    ref
        .read(mapUiStateProvider.notifier)
        .setCamera(
          MapCameraState(
            latitude: cameraState.center.coordinates.lat.toDouble(),
            longitude: cameraState.center.coordinates.lng.toDouble(),
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: cameraState.pitch,
          ),
        );
    _scheduleViewportUpdate(cameraState);
  }

  void _scheduleViewportUpdate(CameraState cameraState) {
    if (_annotationDebounce?.isActive ?? false) return;

    _annotationDebounce?.cancel();
    _annotationDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      if (_shouldUpdateAnnotations(cameraState)) {
        _updateAnnotations();
      }

      if (_shouldUpdateGroups(cameraState)) {
        _updateVisibleGroups();
      }
    });

    _scheduleGeocode(cameraState);
  }

  void _scheduleGeocode(CameraState cameraState) {
    if (_geocodeDebounce?.isActive ?? false) return;

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 600), () async {
      final center = cameraState.center.coordinates;
      final city = await GeocodingService.getCityFromCoordinates(
        center.lat.toDouble(),
        center.lng.toDouble(),
      );
      if (mounted) setState(() => _cityName = city);
    });
  }

  bool _shouldUpdateAnnotations(CameraState cameraState) {
    final zoomStep = cameraState.zoom.floor();
    if (_lastZoomStep == null || _lastZoomStep != zoomStep) {
      _lastZoomStep = zoomStep;
      return true;
    }
    return false;
  }

  bool _shouldUpdateGroups(CameraState cameraState) {
    if (_lastGroupCenter == null) {
      _lastGroupCenter = cameraState.center.coordinates;
      return true;
    }

    final center = cameraState.center.coordinates;
    final latDelta = (center.lat - _lastGroupCenter!.lat).abs();
    final lngDelta = (center.lng - _lastGroupCenter!.lng).abs();
    final shouldUpdate = latDelta >= 0.0005 || lngDelta >= 0.0005;
    if (shouldUpdate) {
      _lastGroupCenter = center;
    }
    return shouldUpdate;
  }

  Future<void> _maybeRefreshClusters(List<Moment> visibleMoments) async {
    final ids = visibleMoments.map((m) => m.id).toList()..sort();
    final newHash = Object.hashAll(ids);
    if (newHash == _momentsHash) return;

    _momentsHash = newHash;
    _log.i('Rebuild cluster for ${visibleMoments.length} moments');
    _rebuildCluster(visibleMoments);
    _updateAnnotations();
    _updateVisibleGroups();

    final mapUiState = ref.read(mapUiStateProvider);
    if (mapUiState.camera == null && visibleMoments.isNotEmpty) {
      final coords = visibleMoments
          .where((m) => m.latitude != 0 && m.longitude != 0)
          .map((m) => Position(m.longitude, m.latitude))
          .toList();
      if (coords.isNotEmpty) {
        final avgLat =
            coords.map((c) => c.lat).reduce((a, b) => a + b) / coords.length;
        final avgLng =
            coords.map((c) => c.lng).reduce((a, b) => a + b) / coords.length;
        _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(avgLng, avgLat)),
            zoom: 12.5,
          ),
          MapAnimationOptions(duration: 700, startDelay: 0),
        );
      }
    }

    final cameraState = await _mapboxMap?.getCameraState();
    if (cameraState != null) {
      _scheduleViewportUpdate(cameraState);
    }
  }

  // ---------------------------------------------------------------------------
  // Supercluster + PointAnnotation avatar markers
  // ---------------------------------------------------------------------------

  void _rebuildCluster(List<Moment> moments) {
    // Group deduplication: Only show one marker per moment group
    final Map<String, Moment> uniqueGroups = {};
    for (final m in moments) {
      if (m.latitude != 0 && m.longitude != 0) {
        // Use momentGroupId if available, otherwise fallback to unique moment ID
        final key = (m.momentGroupId.isNotEmpty) ? m.momentGroupId : m.id;
        // Keep the first one found
        uniqueGroups.putIfAbsent(key, () => m);
      }
    }

    final points = uniqueGroups.values
        .map(
          (m) => _MomentPoint(
            momentId: m.id,
            userId: m.userId ?? '',
            longitude: m.longitude,
            latitude: m.latitude,
            location: m.location,
            title: m.title,
            momentGroupId: m.momentGroupId,
            mediaUrl: m.imageUrl,
            thumbnailUrl: m.thumbnailPath,
            mediaPath: m.mediaPath,
            localMediaPath: m.localMediaPath,
            localThumbnailPath: m.localThumbnailPath,
            mediaType: m.mediaType,
          ),
        )
        .toList();

    // Clear bitmap cache to ensure fresh rendering (e.g. if URLs updated)
    _bitmapCache.clear();

    _log.i('Cluster points: ${points.length}');
    _cluster = SuperclusterImmutable<_MomentPoint>(
      getX: (p) => p.longitude,
      getY: (p) => p.latitude,
      minZoom: 0,
      maxZoom: 22,
      radius: 48,
      extent: 512,
      nodeSize: 64,
    )..load(points);

    // Pre-fetch avatars for all unique user IDs
    final userIds = points
        .map((p) => p.userId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (userIds.isNotEmpty) {
      final avatarService = ref.read(avatarCacheServiceProvider);
      avatarService.preloadAvatars(userIds);
    }
  }

  Future<void> _updateAnnotations() async {
    if (_cluster == null ||
        _mapboxMap == null ||
        _annotationManager == null ||
        _updatingAnnotations) {
      return;
    }

    _updatingAnnotations = true;

    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final bounds = await _mapboxMap!.coordinateBoundsForCamera(
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          bearing: cameraState.bearing,
          pitch: cameraState.pitch,
        ),
      );

      final zoom = cameraState.zoom.floor().clamp(0, 22);
      final boundsKey =
          '${bounds.southwest.coordinates.lat.toStringAsFixed(3)}:'
          '${bounds.southwest.coordinates.lng.toStringAsFixed(3)}:'
          '${bounds.northeast.coordinates.lat.toStringAsFixed(3)}:'
          '${bounds.northeast.coordinates.lng.toStringAsFixed(3)}';

      List<LayerElement<_MomentPoint>> elements;
      final cachedKey = _boundsKeyByZoom[zoom];
      final cachedElements = _elementsByZoom[zoom];
      if (cachedKey == boundsKey && cachedElements != null) {
        elements = cachedElements;
      } else {
        elements = _cluster!.search(
          bounds.southwest.coordinates.lng.toDouble(),
          bounds.southwest.coordinates.lat.toDouble(),
          bounds.northeast.coordinates.lng.toDouble(),
          bounds.northeast.coordinates.lat.toDouble(),
          zoom,
        );
        _elementsByZoom[zoom] = elements;
        _boundsKeyByZoom[zoom] = boundsKey;
      }

      // Generate a stable hash for the current visible elements
      // We use a combination of coordinates and content to ensure unique IDs
      final elementsHash = Object.hashAll(
        elements.map((e) {
          return e.handle(
            cluster: (c) =>
                'c:${c.longitude.toStringAsFixed(5)}:${c.latitude.toStringAsFixed(5)}:${c.childPointCount}',
            point: (p) => 'p:${p.originalPoint.momentId}',
          );
        }),
      );

      if (_lastElementsHash == elementsHash) {
        return;
      }
      _lastElementsHash = elementsHash;

      // 1. Prepare Target Annotations (Parallel Bitmap Generation)
      // We use Future.wait to allow multiple bitmaps to generate/fetch simultaneously
      // logic is moved to helper methods that return efficiently.
      final futures = elements.map((element) {
        return element.handle(
          cluster: (cluster) async {
            final count = cluster.childPointCount;
            final lat = cluster.latitude;
            final lng = cluster.longitude;

            // Stable ID for the annotation
            final annotationId = 'c_${lat}_${lng}_$count';

            final bitmap = await _renderCluster(cluster);

            if (bitmap != null) {
              return (
                id: annotationId,
                momentId: 'cluster_${lng}_${lat}',
                options: PointAnnotationOptions(
                  geometry: Point(coordinates: Position(lng, lat)),
                  image: bitmap,
                  iconSize: 1.0,
                ),
              );
            }
            return null;
          },
          point: (point) async {
            final mp = point.originalPoint;
            final annotationId = 'p_${mp.momentId}';

            // Use moment media for the marker (thumbnail for video, imageUrl for image)
            final mediaUrl = mp.mediaType == 'video'
                ? mp.thumbnailUrl ?? mp.mediaUrl
                : mp.mediaUrl;

            // Cache key uses momentId so each moment has its own thumbnail
            final cacheKey = 'moment_thumb_${mp.momentId}';

            // Resolve signed URL if mediaUrl is missing but mediaPath/thumbnailPath exists
            var effectiveUrl = mediaUrl;
            if ((effectiveUrl == null || effectiveUrl.isEmpty)) {
              final storagePath = mp.mediaType == 'video'
                  ? mp.thumbnailUrl
                  : mp.mediaPath;

              if (storagePath != null &&
                  storagePath.isNotEmpty &&
                  !storagePath.startsWith('http')) {
                effectiveUrl = await SignedUrlCache.getSignedUrl(storagePath);
              }
            }

            final bitmap =
                _bitmapCache[cacheKey] ??
                await _renderMomentThumbnail(
                  effectiveUrl,
                  momentId: mp.momentId,
                  localPath: mp.mediaType == 'video'
                      ? mp.localThumbnailPath
                      : mp.localMediaPath,
                  size: 90,
                );

            if (bitmap != null) {
              _bitmapCache[cacheKey] = bitmap;
              return (
                id: annotationId,
                momentId: mp.momentId,
                options: PointAnnotationOptions(
                  geometry: Point(
                    coordinates: Position(mp.longitude, mp.latitude),
                  ),
                  image: bitmap,
                  iconSize: 1.0,
                ),
              );
            }
            return null;
          },
        );
      });

      final results = await Future.wait(futures);

      // 2. Diffing: Calculate inclusions/exclusions
      final targetAnnotations = <String, PointAnnotationOptions>{};
      final targetMomentIds = <String, String>{};

      for (final result in results) {
        if (result != null) {
          targetAnnotations[result.id] = result.options;
          targetMomentIds[result.id] = result.momentId;
        }
      }

      final targetIds = targetAnnotations.keys.toSet();
      final toDelete = _currentAnnotationIds.difference(targetIds).toList();
      final toAdd = targetIds.difference(_currentAnnotationIds).toList();

      // 3. Apply Changes
      if (toDelete.isNotEmpty) {
        // Mapbox Android/iOS SDKs might accept list of IDs?
        // Flutter wrapper might require iteration or lookup.
        // Actually, deleteMulti accepts list of annotations.
        // But we only have IDs. We need the Annotation objects.
        // The manager.annotations property gives us current annotations.
        final currentAnns = await _annotationManager!.getAnnotations();
        final annsToDelete = currentAnns
            .where((a) => toDelete.contains(_getStableId(a)))
            .toList();

        if (annsToDelete.isNotEmpty) {
          await _annotationManager!.deleteMulti(annsToDelete);
        }
      }

      if (toAdd.isNotEmpty) {
        final optionsToAdd = toAdd.map((id) => targetAnnotations[id]!).toList();
        if (optionsToAdd.isNotEmpty) {
          final newAnns = await _annotationManager!.createMulti(optionsToAdd);
          // We need to attach user-data (stable ID) to the annotation if possible?
          // Mapbox annotations hold a 'customData' field (json)?
          // Or we rely on our map.
          // Since we can't easily store the stable ID on the annotation object itself
          // (unless we use textField or customData if supported),
          // we need a robust way to map back.
          // For now, simpler approach:
          // We maintain _annotationMomentIds map which maps MapboxID -> MomentID.
          // To support diffing delete, we need MapboxID -> StableID.
          // A wrapper map: _aliveAnnotations = Map<StableID, AnnotationID>.

          for (int i = 0; i < newAnns.length; i++) {
            final ann = newAnns[i];
            final id = toAdd[i]; // Matching index
            if (ann != null) {
              _finalAnnotationMap[id] = ann.id; // StableID -> MapboxID
              _annotationMomentIds[ann.id] = targetMomentIds[id]!;
            }
          }
        }
      }

      _currentAnnotationIds.clear();
      _currentAnnotationIds.addAll(targetIds);
    } catch (e) {
      _log.w('Failed to update annotations: $e');
    } finally {
      _updatingAnnotations = false;
    }
  }

  // Helper to allow Delete to work
  // We need to store MapboxID for each StableID
  final Map<String, String> _finalAnnotationMap = {};

  String? _getStableId(PointAnnotation ann) {
    // Reverse lookup? Expensive.
    // Better: store in _finalAnnotationMap.
    // _finalAnnotationMap: StableID -> MapboxID.
    // keys are StableIDs. values are MapboxIDs.
    // We want to find StableID for a given Mapbox Annotation (ann).
    // Actually, we only need to look up MapboxID from StableID for deletion.
    return _finalAnnotationMap.keys.firstWhere(
      (k) => _finalAnnotationMap[k] == ann.id,
      orElse: () => '',
    );
  }

  void _onAnnotationTapped(PointAnnotation annotation) async {
    final id = _annotationMomentIds[annotation.id];
    if (id == null) return;

    // Open moment details
    final moment = _allVisibleMoments.where((m) => m.id == id).firstOrNull;
    if (moment == null) return;

    final groups = MapLogicService.groupMomentsByPlace(
      _allVisibleMoments,
      _currentZoom,
    );
    final group = groups.firstWhere(
      (g) => (g['moments'] as List<Moment>).any((m) => m.id == id),
      orElse: () => {
        'moments': [moment],
        'placeName': moment.location,
      },
    );
    _onMomentGroupTapped(group['moments'] as List<Moment>);
  }

  /// Handle tap on a live friend marker — trigger pulse animation.
  void _onLiveFriendTapped(PointAnnotation annotation) async {
    if (_mapboxMap == null) return;
    final coords = annotation.geometry.coordinates;
    final screenPoint = await _mapboxMap!.pixelForCoordinate(
      Point(coordinates: Position(coords.lng, coords.lat)),
    );
    _triggerPulseAt(Offset(screenPoint.x, screenPoint.y));
    HapticService.lightTap();
  }

  // =========================================================================
  // Live Friend Annotations (Ghost Mode)
  // =========================================================================

  /// Diff live friends and update annotations on the map.
  Future<void> _updateLiveFriendAnnotations(
    Map<String, LiveFriend> friends,
  ) async {
    if (_liveFriendAnnotationManager == null || _mapboxMap == null) return;

    final incomingIds = friends.keys.toSet();
    final toRemove = _currentLiveFriendIds.difference(incomingIds);
    final toAdd = incomingIds.difference(_currentLiveFriendIds);
    final toUpdate = incomingIds.intersection(_currentLiveFriendIds);

    // Force clear all if the new list is empty (Robust cleanup)
    if (friends.isEmpty) {
      // Logic: If we have ANY tracking IDs, we should clear them.
      // Also if we have any annotations in the manager (orphan check).
      if (_liveFriendAnnotationIds.isNotEmpty) {
        _log.i(
          'Friend list empty. Force clearing all live friend annotations.',
        );
        try {
          await _liveFriendAnnotationManager?.deleteAll();
          _liveFriendAnnotationIds.clear();
          _currentLiveFriendIds.clear();
        } catch (e) {
          _log.w('Failed to clear all live friend annotations: $e');
        }
      }
      return;
    }

    // Remove stale annotations
    if (toRemove.isNotEmpty) {
      try {
        final currentAnns = await _liveFriendAnnotationManager!
            .getAnnotations();
        final annsToDelete = currentAnns.where((a) {
          // Find the userId for this annotation ID
          final userId = _liveFriendAnnotationIds.entries
              .where((e) => e.value == a.id)
              .map((e) => e.key)
              .firstOrNull;
          // If we found a userId and they are in the removal list, delete it.
          // ALSO delete if we can't find a userId map (orphan annotation).
          return (userId != null && toRemove.contains(userId));
        }).toList();

        if (annsToDelete.isNotEmpty) {
          await _liveFriendAnnotationManager!.deleteMulti(annsToDelete);
        }
      } catch (e) {
        _log.w('Failed to remove live friend annotations: $e');
      }
      // Always remove from our local tracking map
      for (final id in toRemove) {
        _liveFriendAnnotationIds.remove(id);
      }
    }

    // Add new annotations
    for (final userId in toAdd) {
      final friend = friends[userId]!;
      final bitmap = await _renderLiveFriendMarker(
        friend.avatarUrl,
        userId: friend.userId,
      );
      if (bitmap == null) continue;
      try {
        final ann = await _liveFriendAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(friend.longitude, friend.latitude),
            ),
            image: bitmap,
            iconSize: 0.75,
            iconAnchor: IconAnchor.CENTER,
          ),
        );
        _liveFriendAnnotationIds[userId] = ann.id;
      } catch (e) {
        _log.w('Failed to add live friend annotation: $e');
      }
    }

    // Update positions AND images for existing annotations
    for (final userId in toUpdate) {
      final friend = friends[userId]!;
      final mapboxId = _liveFriendAnnotationIds[userId];
      if (mapboxId == null) continue;
      try {
        final currentAnns = await _liveFriendAnnotationManager!
            .getAnnotations();
        final ann = currentAnns.where((a) => a.id == mapboxId).firstOrNull;

        if (ann != null) {
          // 1. Update Position
          final newPos = Point(
            coordinates: Position(friend.longitude, friend.latitude),
          );
          ann.geometry = newPos;

          // 2. Update Image (Refresh bitmap in case avatar loaded)
          final bitmap = await _renderLiveFriendMarker(
            friend.avatarUrl,
            userId: friend.userId,
          );
          if (bitmap != null) {
            ann.image = bitmap;
          }

          // 3. Commit updates
          await _liveFriendAnnotationManager!.update(ann);
        }
      } catch (e) {
        _log.w('Failed to update live friend annotation: $e');
      }
    }

    _currentLiveFriendIds.clear();
    _currentLiveFriendIds.addAll(incomingIds);
    _log.d('Live friend annotations updated: ${friends.length} friends');
  }

  /// Render a circular avatar bitmap with a green online-indicator dot.
  Future<Uint8List?> _renderLiveFriendMarker(
    String? avatarUrl, {
    String? userId,
    double size = 100,
    double borderWidth = 3.5,
  }) async {
    try {
      final totalSize = size + 12; // Extra space for shadow + online dot
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final center = Offset(totalSize / 2, totalSize / 2 - 2);
      final radius = size / 2;

      // Drop shadow
      canvas.drawCircle(
        Offset(center.dx, center.dy + 3),
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // White fill
      canvas.drawCircle(center, radius, Paint()..color = Colors.white);

      // Green border (live indicator)
      canvas.drawCircle(
        center,
        radius - borderWidth / 2,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      // Avatar image or fallback
      final innerRadius = radius - borderWidth - 1;
      final ui.Image? image = _loadAvatarImage(avatarUrl, userId: userId);
      if (image != null) {
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: center, radius: innerRadius),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        // Fallback: tinted circle with person silhouette
        canvas.drawCircle(
          center,
          innerRadius,
          Paint()..color = Colors.green.withValues(alpha: 0.12),
        );
        final iconPaint = Paint()..color = Colors.green.withValues(alpha: 0.5);
        canvas.drawCircle(
          Offset(center.dx, center.dy - innerRadius * 0.1),
          innerRadius * 0.3,
          iconPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + innerRadius * 0.45),
            width: innerRadius * 0.7,
            height: innerRadius * 0.5,
          ),
          iconPaint,
        );

        // Loading Spinner (if we are waiting for an image)
        final spinnerPaint = Paint()
          ..color = AppTheme.vibrantGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius * 0.4),
          -pi / 2,
          3 * pi / 2, // 270 degrees
          false,
          spinnerPaint,
        );
      }

      // Green online dot (bottom-right)
      final dotRadius = size * 0.13;
      final dotCenter = Offset(
        center.dx + radius * 0.65,
        center.dy + radius * 0.65,
      );
      // White border ring for the dot
      canvas.drawCircle(
        dotCenter,
        dotRadius + 2.5,
        Paint()..color = Colors.white,
      );
      // Green fill
      canvas.drawCircle(dotCenter, dotRadius, Paint()..color = Colors.green);

      final picture = recorder.endRecording();
      final img = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Live friend marker render failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Bitmap rendering helpers
  // ---------------------------------------------------------------------------

  /// Render a single circle avatar bitmap from an avatar URL.
  /// Uses a drop shadow + crisp white border for a premium look.
  Future<Uint8List?> _renderAvatarBitmap(
    String? avatarUrl, {
    String? userId,
    double size = 100,
    double borderWidth = 3.5,
  }) async {
    try {
      final totalSize = size + 8; // Extra space for shadow
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final center = Offset(totalSize / 2, totalSize / 2 - 2);

      // Drop shadow
      canvas.drawCircle(
        Offset(center.dx, center.dy + 3),
        size / 2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // White fill
      canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);

      // Blue accent border
      canvas.drawCircle(
        center,
        size / 2 - borderWidth / 2,
        Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      final ui.Image? image = _loadAvatarImage(avatarUrl, userId: userId);
      if (image != null) {
        final innerRadius = size / 2 - borderWidth - 1;
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: center, radius: innerRadius),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        // Fallback: solid colored circle with initial
        final innerRadius = size / 2 - borderWidth - 1;
        canvas.drawCircle(
          center,
          innerRadius,
          Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.15),
        );
        // Draw a person icon placeholder
        final iconPaint = Paint()
          ..color = AppTheme.primaryBlue.withValues(alpha: 0.5);
        canvas.drawCircle(
          Offset(center.dx, center.dy - innerRadius * 0.1),
          innerRadius * 0.3,
          iconPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + innerRadius * 0.45),
            width: innerRadius * 0.7,
            height: innerRadius * 0.5,
          ),
          iconPaint,
        );
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Avatar bitmap render failed: $e');
      return null;
    }
  }

  // Cache for moment media images (separate from avatar cache)
  final Map<String, ui.Image> _loadedMomentImages = {};
  final Set<String> _loadingMomentImages = {};

  /// Render a circular moment thumbnail for map annotations.
  /// Shows moment media image inside a circle with a white border.
  Future<Uint8List?> _renderMomentThumbnail(
    String? mediaUrl, {
    String? momentId,
    String? localPath,
    double size = 90,
    double borderWidth = 3.0,
  }) async {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      _log.w('Moment $momentId has NO media URL');
    } else {
      _log.d('Rendering thumbnail for moment $momentId with URL: $mediaUrl');
    }
    try {
      final totalSize = size + 10; // shadow margin
      final center = Offset(totalSize / 2, totalSize / 2 - 1);
      final radius = size / 2;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Drop shadow
      canvas.drawCircle(
        center + const Offset(0, 3),
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // White background fill
      canvas.drawCircle(center, radius, Paint()..color = Colors.white);

      // Blue accent border
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      // Inner circle for the image
      final innerRadius = radius - borderWidth - 1;

      final ui.Image? image = _loadMomentImage(
        mediaUrl,
        momentId: momentId,
        localPath: localPath,
      );
      if (image != null) {
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: center, radius: innerRadius),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        // Fallback: Loading Spinner or Placeholder
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
        );

        // Background
        canvas.drawCircle(
          center,
          innerRadius,
          Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.12),
        );

        // Draw Spinner (Static representation for map bitmap)
        // Since this is a static bitmap, we can't animate it easily.
        // We draw a "loading" arc to indicate progress.
        final spinnerPaint = Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius * 0.4),
          -pi / 2,
          3 * pi / 2, // 270 degrees
          false,
          spinnerPaint,
        );

        canvas.restore();
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Moment thumbnail render failed: $e');
      return null;
    }
  }

  /// Load and cache a moment's media image (local file -> network -> raster).
  ui.Image? _loadMomentImage(
    String? mediaUrl, {
    String? momentId,
    String? localPath,
  }) {
    // 1. Try Local File first
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        final key = 'local:$localPath';
        if (_loadedMomentImages.containsKey(key)) {
          return _loadedMomentImages[key];
        }

        if (!_loadingMomentImages.contains(key)) {
          _loadingMomentImages.add(key);
          // Load local file
          FileImage(file)
              .resolve(ImageConfiguration.empty)
              .addListener(
                ImageStreamListener(
                  (info, _) {
                    if (mounted) {
                      setState(() {
                        _loadedMomentImages[key] = info.image;
                        _loadingMomentImages.remove(key);
                        // Invalidate to force re-render
                        _bitmapCache.removeWhere(
                          (k, _) => k.startsWith('moment_thumb_'),
                        );
                        _bitmapCache.removeWhere(
                          (k, _) => k.startsWith('cluster_'),
                        );
                        _lastElementsHash = null;
                        if (!_updatingAnnotations && _mapboxMap != null) {
                          _mapboxMap!.getCameraState().then((cam) {
                            if (mounted) _scheduleViewportUpdate(cam);
                          });
                        }
                      });
                    }
                  },
                  onError: (e, _) {
                    _log.w(
                      'Failed to load local moment image ($localPath): $e',
                    );
                    if (mounted) {
                      _loadingMomentImages.remove(key);
                    }
                  },
                ),
              );
        }
        return null; // Loading
      }
    }

    // 2. Fallback to Network URL
    if (mediaUrl == null || mediaUrl.isEmpty) return null;

    if (_loadedMomentImages.containsKey(mediaUrl)) {
      return _loadedMomentImages[mediaUrl];
    }

    if (!_loadingMomentImages.contains(mediaUrl)) {
      _loadingMomentImages.add(mediaUrl);

      final provider = CachedNetworkImageProvider(mediaUrl);
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) {
                if (mounted) {
                  setState(() {
                    _loadedMomentImages[mediaUrl] = info.image;
                    _loadingMomentImages.remove(mediaUrl);

                    // Invalidate moment thumbnail bitmaps so they re-render
                    _bitmapCache.removeWhere(
                      (key, _) => key.startsWith('moment_thumb_'),
                    );
                    _bitmapCache.removeWhere(
                      (k, _) => k.startsWith('cluster_'),
                    );

                    _lastElementsHash = null;
                    if (!_updatingAnnotations && _mapboxMap != null) {
                      _mapboxMap!.getCameraState().then((cam) {
                        if (mounted) _scheduleViewportUpdate(cam);
                      });
                    }
                  });
                }
              },
              onError: (e, _) {
                _log.e('Failed to load moment image ($mediaUrl): $e');
                if (mounted) {
                  _loadingMomentImages.remove(mediaUrl);
                }
              },
            ),
          );
    }
    return null;
  }

  ui.Image? _loadAvatarImage(String? avatarUrl, {String? userId}) {
    final avatarService = ref.read(avatarCacheServiceProvider);
    var resolvedUrl = avatarUrl;

    if ((resolvedUrl == null || resolvedUrl.isEmpty) && userId != null) {
      resolvedUrl = avatarService.getAvatarUrlSync(userId);
      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        unawaited(avatarService.getAvatarUrl(userId));
        return null;
      }
    }

    if (resolvedUrl == null || resolvedUrl.isEmpty) return null;
    final url = resolvedUrl;
    if (_loadedAvatars.containsKey(url)) {
      return _loadedAvatars[url];
    }

    if (!_loadingAvatars.contains(url)) {
      _loadingAvatars.add(url);

      // Use AvatarCacheService for local-first loading (FileImage if cached)
      final provider =
          avatarService.getAvatarImageProvider(url) ??
          CachedNetworkImageProvider(url);

      provider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) {
                if (mounted) {
                  setState(() {
                    _loadedAvatars[url] = info.image;
                    _loadingAvatars.remove(url);

                    // Invalidate all avatar bitmaps
                    _bitmapCache.clear();

                    // Force re-evaluation of live friends specifically
                    // to pick up the new avatar
                    if (_latestLiveFriends.isNotEmpty) {
                      _updateLiveFriendAnnotations(_latestLiveFriends);
                    }

                    _lastElementsHash = null;

                    if (!_updatingAnnotations && _mapboxMap != null) {
                      _mapboxMap!.getCameraState().then((cam) {
                        if (mounted) _scheduleViewportUpdate(cam);
                      });
                    }
                  });
                }
              },
              onError: (e, _) {
                if (mounted) {
                  _loadingAvatars.remove(url);
                }
              },
            ),
          );
    }
    return null;
  }

  Future<Uint8List?> _renderCluster(LayerCluster<_MomentPoint> cluster) async {
    final count = cluster.childPointCount;
    // Collect the top few moments in this cluster to show as a stack
    final moments = _collectClusterMoments(cluster, limit: 3);

    // Create a cache key from moment IDs + count
    final cacheKey =
        'cluster_${moments.map((m) => m.momentId).join('_')}_$count';

    if (_bitmapCache.containsKey(cacheKey)) {
      return _bitmapCache[cacheKey];
    }

    final bitmap = await _renderClusterMomentStack(
      moments: moments,
      clusterCount: count,
      totalMoments: count,
    );

    if (bitmap != null) {
      _bitmapCache[cacheKey] = bitmap;
    }
    return bitmap;
  }

  List<_MomentPoint> _collectClusterMoments(
    LayerCluster<_MomentPoint> cluster, {
    int limit = 3,
  }) {
    if (_cluster == null) return [];
    final moments = <_MomentPoint>[];
    final pending = <LayerElement<_MomentPoint>>[];
    pending.addAll(_cluster!.childrenOf(cluster));

    while (pending.isNotEmpty && moments.length < limit) {
      final element = pending.removeLast();
      element.handle(
        cluster: (c) => pending.addAll(_cluster!.childrenOf(c)),
        point: (p) {
          final m = p.originalPoint;
          // Avoid duplicates by momentId
          if (!moments.any((existing) => existing.momentId == m.momentId)) {
            moments.add(m);
          }
        },
      );
    }
    return moments;
  }

  /// Render a cluster marker as an overlapping vertical stack of MOMENT images.
  Future<Uint8List?> _renderClusterMomentStack({
    required List<_MomentPoint> moments,
    int clusterCount = 0,
    int totalMoments = 0,
  }) async {
    const double radius = 50;
    const double diameter = radius * 2; // 100
    const double borderWidth = 3.5;
    const double overlap = 30; // horizontal overlap

    final count = moments.length.clamp(1, 3);
    final overflowCount = totalMoments - count;
    final hasOverflow = overflowCount > 0;

    // Total items: visible moments + overflow circle (if any)
    final totalItems = count + (hasOverflow ? 1 : 0);
    // Total width
    final totalWidth = diameter + (totalItems - 1) * (diameter - overlap) + 12;
    const totalHeight = diameter + 12; // extra for shadow + badge

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw moments right-to-left so the FIRST one (index 0) is on TOP (last drawn)
      // Actually, standard stack: 0 is top, 1 is behind.
      // So we must draw in reverse order: 2, then 1, then 0.
      for (int i = count - 1; i >= 0; i--) {
        final moment = moments[i];
        final xOffset = i * (diameter - overlap);
        final center = Offset(xOffset + radius + 2, radius + 4);

        // Drop shadow
        canvas.drawCircle(
          Offset(center.dx, center.dy + 3),
          radius,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        // White fill
        canvas.drawCircle(center, radius, Paint()..color = Colors.white);

        // Border
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = AppTheme.primaryBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth,
        );

        // Image
        final innerRadius = radius - borderWidth - 1;

        var url = moment.mediaUrl;
        if (url == null || url.isEmpty) {
          final storagePath = moment.mediaType == 'video'
              ? moment.thumbnailUrl
              : moment.mediaPath;
          if (storagePath != null &&
              storagePath.isNotEmpty &&
              !storagePath.startsWith('http')) {
            url = await SignedUrlCache.getSignedUrl(storagePath);
          }
        }

        final ui.Image? image = _loadMomentImage(
          url,
          momentId: moment.momentId,
          localPath: moment.mediaType == 'video'
              ? moment.localThumbnailPath
              : moment.localMediaPath,
        );

        if (image != null) {
          canvas.save();
          canvas.clipPath(
            Path()
              ..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
          );
          paintImage(
            canvas: canvas,
            rect: Rect.fromCircle(center: center, radius: innerRadius),
            image: image,
            fit: BoxFit.cover,
          );
          canvas.restore();
        } else {
          // Fallback blue fill
          canvas.drawCircle(
            center,
            innerRadius,
            Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.15),
          );

          // Draw Spinner
          final spinnerPaint = Paint()
            ..color = AppTheme.primaryBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round;

          canvas.drawArc(
            Rect.fromCircle(center: center, radius: innerRadius * 0.4),
            -pi / 2,
            3 * pi / 2, // 270 degrees
            false,
            spinnerPaint,
          );
        }
      }

      // Draw overflow badge if needed
      if (hasOverflow) {
        // Position it as the last item in the stack (furthest right/bottom)
        final xOffset = count * (diameter - overlap);
        final center = Offset(xOffset + radius + 2, radius + 4);

        // Shadow
        canvas.drawCircle(
          Offset(center.dx, center.dy + 3),
          radius,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        // Background
        canvas.drawCircle(center, radius, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = AppTheme.primaryBlue.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill,
        );
        // Border
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = AppTheme.primaryBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth,
        );

        // Text
        final textSpan = TextSpan(
          text: '+$overflowCount',
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2,
          ),
        );
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        totalWidth.toInt(),
        totalHeight.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Cluster stack render failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Viewport-aware card filtering
  // ---------------------------------------------------------------------------

  Future<void> _updateVisibleGroups() async {
    if (_allVisibleMoments.isEmpty || _mapboxMap == null) return;

    final groups = MapLogicService.groupMomentsByPlace(
      _allVisibleMoments,
      _currentZoom,
    );
    final filtered = await _filterGroupsToViewport(groups);

    if (mounted) {
      setState(() {
        _visibleGroups = filtered;
        final currentIndex = ref.read(mapUiStateProvider).selectedGroupIndex;
        if (currentIndex >= filtered.length) {
          ref.read(mapUiStateProvider.notifier).setSelectedGroupIndex(0);
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _filterGroupsToViewport(
    List<Map<String, dynamic>> groups,
  ) async {
    if (_mapboxMap == null) return groups;

    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final bounds = await _mapboxMap!.coordinateBoundsForCamera(
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          bearing: cameraState.bearing,
          pitch: cameraState.pitch,
        ),
      );

      return groups.where((group) {
        final lat = group['lat'] as double;
        final lng = group['lng'] as double;
        return lat >= bounds.southwest.coordinates.lat &&
            lat <= bounds.northeast.coordinates.lat &&
            lng >= bounds.southwest.coordinates.lng &&
            lng <= bounds.northeast.coordinates.lng;
      }).toList();
    } catch (e) {
      _log.w('Viewport bounds query failed: $e');
      return groups;
    }
  }

  // ---------------------------------------------------------------------------
  // Media picker helpers (ported from map_page_mapbox.dart)
  // ---------------------------------------------------------------------------

  Future<bool> _ensureLocation() async {
    if (_currentPosition != null) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting location...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Try reading — succeeds if permission already granted
    await _initializeLocation();
    if (_currentPosition != null) return true;

    // Re-enable puck which may re-trigger Mapbox's native prompt
    await _enableLocationPuck();

    // Wait and retry a few times
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await _initializeLocation();
      if (_currentPosition != null) return true;
    }

    if (mounted) {
      context.showErrorSnackBar('Unable to get current location');
    }
    return false;
  }

  Future<void> _pickFromCamera({required String mediaType}) async {
    final picker.ImagePicker imagePicker = picker.ImagePicker();
    try {
      if (!await _ensureLocation()) return;
      if (!mounted) return;

      picker.XFile? file;

      if (mediaType == 'photo') {
        file = await imagePicker.pickImage(
          source: picker.ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      } else {
        file = await imagePicker.pickVideo(
          source: picker.ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file == null || !mounted) return;

      if (!await _ensureLocation()) return;
      if (!mounted) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPath: file!.path,
            isVideo: mediaType == 'video',
            initialLatitude: _currentPosition!.latitude!,
            initialLongitude: _currentPosition!.longitude!,
          ),
        ),
      );

      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error opening camera: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await _ensureLocation()) return;
    if (!mounted) return; // Add mounted check

    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 10,
          requestType: pm.RequestType.common,
          specialPickerType: SpecialPickerType.noPreview,
        ),
      );

      if (assets == null || assets.isEmpty || !mounted) return;

      final List<String> mediaPaths = [];
      bool hasVideo = false;
      int? videoDuration;

      for (final asset in assets) {
        final file = await asset.file;
        if (file != null) {
          mediaPaths.add(file.path);
          if (asset.type == AssetType.video) {
            hasVideo = true;
            videoDuration = asset.duration;
          }
        }
      }

      if (mediaPaths.isEmpty || !mounted) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPaths: mediaPaths,
            isVideo: hasVideo,
            videoDuration: videoDuration ?? 0,
            initialLatitude: _currentPosition!.latitude!,
            initialLongitude: _currentPosition!.longitude!,
          ),
        ),
      );

      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error picking media: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _onMomentGroupTapped(List<Moment> moments) {
    HapticService.mediumTap();
    final placeName = moments.first.location.split(',').first.trim();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => MomentDetailsPage(
              locationName: placeName,
              moments: moments,
              heroTag: null,
              initialPage: 0,
            ),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
          ),
        )
        .whenComplete(() => ref.invalidate(momentsStreamProvider));
  }

  void _onCardTapped(Map<String, dynamic> group) {
    _onMomentGroupTapped(group['moments'] as List<Moment>);
  }

  /// Card swiped — only update the selected index.
  void _onCardSelected(int index) {
    if (index >= _visibleGroups.length) return;
    ref.read(mapUiStateProvider.notifier).setSelectedGroupIndex(index);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mapUiState = ref.watch(mapUiStateProvider);
    final momentsAsync = ref.watch(momentsStreamProvider);
    final notificationCount = ref.watch(notificationCountProvider).value ?? 0;
    final currentUserId = _authService.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      extendBodyBehindAppBar: true,
      appBar: BlurredAppBar(
        title: 'MOMENTS',
        profileImageUrl: _authService.currentUserPhotoUrl,
        notificationCount: notificationCount,
        onMenuPressed: () {},
        onProfilePressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ),
        onFriendsPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendsPage()),
        ),
        onNotificationsPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        ),
      ),
      body: momentsAsync.when(
        data: (moments) {
          final visibleMoments = moments.where((m) {
            return m.userId == currentUserId || !m.isPrivate;
          }).toList();

          _allVisibleMoments = visibleMoments;

          if (_isMapReady && _isStyleLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeRefreshClusters(visibleMoments);
            });
          }

          return _buildMapBody(mapUiState);
        },
        loading: () => _buildMapBody(mapUiState),
        error: (e, _) {
          _log.e('Moments stream error: $e');
          return _buildMapBody(mapUiState);
        },
      ),
    );
  }

  Widget _buildMapBody(MapUiState mapUiState) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        // ── Native Mapbox map ──
        MapWidget(
          key: const ValueKey('mapbox_v2'),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          cameraOptions: CameraOptions(
            center: mapUiState.camera != null
                ? Point(
                    coordinates: Position(
                      mapUiState.camera!.longitude,
                      mapUiState.camera!.latitude,
                    ),
                  )
                : _currentPosition != null
                ? Point(
                    coordinates: Position(
                      _currentPosition!.longitude!,
                      _currentPosition!.latitude!,
                    ),
                  )
                : Point(coordinates: Position(0, 20)), // World View fallback
            zoom:
                mapUiState.camera?.zoom ??
                (_currentPosition != null ? 14.0 : 1.5),
          ),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapIdleListener: _onMapIdle,
          onCameraChangeListener: _onCameraChanged,
        ),

        // ── City / location label ──
        if (_cityName.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            left: 0,
            right: 0,
            child: Center(child: LocationLabel(cityName: _cityName)),
          ),

        // ── Bottom card carousel ──
        if (_visibleGroups.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80 + bottomPadding,
            child: MomentCardsCarousel(
              groups: _visibleGroups,
              selectedIndex: mapUiState.selectedGroupIndex,
              onCardTapped: _onCardTapped,
              onCardChanged: _onCardSelected,
            ),
          ),

        // ── FAB (bottom-left, next to floating navbar) ──
        Positioned(
          right: 16,
          bottom: 20 + bottomPadding,
          child: _MomentsFAB(
            onCameraTap: () => _pickFromCamera(mediaType: 'photo'),
            onVideoTap: () => _pickFromCamera(mediaType: 'video'),
            onGalleryTap: _pickFromGallery,
          ),
        ),

        // ── Ghost Mode toggle (bottom-left) ──
        Positioned(
          left: 16,
          bottom: 20 + bottomPadding,
          child: _GhostModeButton(
            currentPosition: _currentPosition,
            displayName: _authService.currentUserDisplayName,
            avatarUrl: _authService.currentUserPhotoUrl,
          ),
        ),

        // ── Feature 1: Pulse overlay ──
        if (_showPulse && _pulseCenter != null)
          PulseLayer(
            center: _pulseCenter!,
            onComplete: () => setState(() => _showPulse = false),
          ),
      ],
    );
  }
}

// =============================================================================
// Moments FAB – 3-option speed dial (Camera, Video, Gallery)
// =============================================================================

class _MomentsFAB extends StatefulWidget {
  const _MomentsFAB({
    required this.onCameraTap,
    required this.onVideoTap,
    required this.onGalleryTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onVideoTap;
  final VoidCallback onGalleryTap;

  @override
  State<_MomentsFAB> createState() => _MomentsFABState();
}

class _MomentsFABState extends State<_MomentsFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticService.lightTap();
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _handleAction(VoidCallback action) {
    HapticService.mediumTap();
    _toggle();
    Future.delayed(const Duration(milliseconds: 200), action);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options (appear above the main button)
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 2, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOption(
                    icon: CupertinoIcons.photo_on_rectangle,
                    label: 'Gallery',
                    color: AppTheme.brightYellow,
                    textColor: Colors.black,
                    onTap: () => _handleAction(widget.onGalleryTap),
                  ),
                  const SizedBox(height: 8),
                  _buildOption(
                    icon: CupertinoIcons.video_camera_solid,
                    label: 'Video',
                    color: AppTheme.coralPink,
                    textColor: Colors.white,
                    onTap: () => _handleAction(widget.onVideoTap),
                  ),
                  const SizedBox(height: 8),
                  _buildOption(
                    icon: CupertinoIcons.camera_fill,
                    label: 'Camera',
                    color: Colors.white,
                    textColor: AppTheme.primaryBlue,
                    onTap: () => _handleAction(widget.onCameraTap),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main FAB button
        SpringButton(
          onTap: _toggle,
          scaleFactor: 0.9,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      scaleFactor: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Ghost Mode Toggle Button – off / live / transitioning
// =============================================================================

class _GhostModeButton extends ConsumerStatefulWidget {
  const _GhostModeButton({
    required this.currentPosition,
    this.displayName,
    this.avatarUrl,
  });

  final LocationData? currentPosition;
  final String? displayName;
  final String? avatarUrl;

  @override
  ConsumerState<_GhostModeButton> createState() => _GhostModeButtonState();
}

class _GhostModeButtonState extends ConsumerState<_GhostModeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final service = ref.read(ghostModeServiceProvider);
    final isLive = ref.read(isGhostLiveProvider);
    final pos = widget.currentPosition;

    if (!isLive) {
      // Going live — confirm first
      if (pos == null || pos.latitude == null || pos.longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not available')),
          );
        }
        return;
      }

      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Go Live?'),
          content: const Text(
            'Your friends will see your live location on the map. You can stop sharing anytime.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Go Live'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      setState(() => _isTransitioning = true);
      await Future.delayed(const Duration(milliseconds: 400));
      service.goLive(
        latitude: pos.latitude!,
        longitude: pos.longitude!,
        displayName: widget.displayName,
        avatarUrl: widget.avatarUrl,
      );
      ref.read(isGhostLiveProvider.notifier).set(true);
      _pulseController.repeat();
    } else {
      // Going offline
      setState(() => _isTransitioning = true);
      await Future.delayed(const Duration(milliseconds: 300));
      service.goOffline();
      ref.read(isGhostLiveProvider.notifier).set(false);
      _pulseController.stop();
      _pulseController.reset();
    }

    if (mounted) setState(() => _isTransitioning = false);
    HapticService.mediumTap();
  }

  @override
  Widget build(BuildContext context) {
    final isLive = ref.watch(isGhostLiveProvider);

    return GestureDetector(
      onTap: _isTransitioning ? null : _toggle,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isLive ? 1.0 + (_pulseController.value * 0.15) : 1.0;
          final glowOpacity = isLive
              ? (1.0 - _pulseController.value) * 0.5
              : 0.0;

          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLive
                  ? AppTheme.vibrantGreen.withValues(alpha: 0.15)
                  : AppTheme.backgroundBeige.withValues(alpha: 0.85),
              border: Border.all(
                color: isLive
                    ? AppTheme.vibrantGreen.withValues(alpha: 0.6)
                    : AppTheme.borderGray.withValues(alpha: 0.3),
                width: isLive ? 2.5 : 1.0,
              ),
            ),
            child: _isTransitioning
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: isLive
                            ? AppTheme.vibrantGreen
                            : AppTheme.textGray,
                      ),
                    ),
                  )
                : Icon(
                    isLive
                        ? CupertinoIcons.location_fill
                        : CupertinoIcons.location,
                    size: 24,
                    color: isLive
                        ? AppTheme.vibrantGreen
                        : AppTheme.textGray.withValues(alpha: 0.5),
                  ),
          );
        },
      ),
    );
  }
}

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  _AnnotationClickListener(this.onTap);

  final void Function(PointAnnotation annotation) onTap;

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
    return true;
  }
}

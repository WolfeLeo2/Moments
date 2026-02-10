import 'dart:async';
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

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/avatar_cache_service.dart';
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

  const _MomentPoint({
    required this.momentId,
    required this.userId,
    required this.longitude,
    required this.latitude,
    required this.location,
    required this.title,
    required this.momentGroupId,
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
  final AuthService _authService = AuthService();

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
  SuperclusterImmutable<_MomentPoint>? _cluster;
  PointAnnotationManager? _annotationManager;
  final Map<String, Uint8List> _bitmapCache = {};
  final Map<String, Future<ui.Image?>> _avatarImageCache = {};
  bool _updatingAnnotations = false;
  int _momentsHash = 0;
  int? _lastElementsHash;
  int? _lastZoomStep;
  Position? _lastGroupCenter;
  final Map<int, List<LayerElement<_MomentPoint>>> _elementsByZoom = {};
  final Map<int, String> _boundsKeyByZoom = {};
  late final _AnnotationClickListener _annotationClickListener;

  // Map annotation → moment ID for tap handling
  final Map<String, String> _annotationMomentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapboxOptions.setAccessToken(_mapboxAccessToken);
    _annotationClickListener = _AnnotationClickListener(_onAnnotationTapped);
    _initializeLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _annotationDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _annotationManager = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location (one-shot for initial camera, not continuous)
  // ---------------------------------------------------------------------------

  Future<void> _initializeLocation() async {
    final location = Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final loc = await location.getLocation();
      if (mounted) {
        setState(() => _currentPosition = loc);
        if (_isMapReady) _flyToUserLocation();
      }
    } catch (e) {
      _log.e('Location init error: $e');
    }
  }

  Future<void> _flyToUserLocation() async {
    if (_currentPosition == null || _mapboxMap == null) return;
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
  }

  // ---------------------------------------------------------------------------
  // Map lifecycle callbacks
  // ---------------------------------------------------------------------------

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _log.i('Map created');

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: AppTheme.primaryBlue.toARGB32(),
        showAccuracyRing: false,
      ),
    );

    _isMapReady = true;
    if (_currentPosition != null) {
      _flyToUserLocation();
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    _isStyleLoaded = true;
    _log.i('Style loaded');

    if (_mapboxMap == null) return;

    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
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
    final points = moments
        .where((m) => m.latitude != 0 && m.longitude != 0)
        .map(
          (m) => _MomentPoint(
            momentId: m.id,
            userId: m.userId ?? '',
            longitude: m.longitude,
            latitude: m.latitude,
            location: m.location,
            title: m.title,
            momentGroupId: m.momentGroupId,
          ),
        )
        .toList();

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
      _log.i(
        'Skip updateAnnotations: '
        'cluster=${_cluster != null}, '
        'map=${_mapboxMap != null}, '
        'manager=${_annotationManager != null}, '
        'busy=$_updatingAnnotations',
      );
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
        _log.i('Use cached elements: ${elements.length} at zoom $zoom');
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
        _log.i('Search elements: ${elements.length} at zoom $zoom');
      }

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
        _log.i('Skip updateAnnotations: no visible changes');
        return;
      }
      _lastElementsHash = elementsHash;

      // Clear existing annotations
      await _annotationManager!.deleteAll();
      _annotationMomentIds.clear();

      final avatarService = ref.read(avatarCacheServiceProvider);
      final options = <PointAnnotationOptions>[];
      final momentIdList = <String>[];

      for (final element in elements) {
        element.handle(
          cluster: (cluster) async {
            final count = cluster.childPointCount;
            final userIds = _collectClusterUserIds(cluster, limit: 3);

            final key = 'cluster_stack_${userIds.join('_')}_$count';
            final bitmap =
                _bitmapCache[key] ??
                await _renderClusterAvatarStack(
                  userIds: userIds,
                  avatarService: avatarService,
                );

            if (bitmap != null) {
              _bitmapCache[key] = bitmap;
              options.add(
                PointAnnotationOptions(
                  geometry: Point(
                    coordinates: Position(cluster.longitude, cluster.latitude),
                  ),
                  image: bitmap,
                  iconSize: 1.0,
                ),
              );
              momentIdList.add(
                'cluster_${cluster.longitude}_${cluster.latitude}',
              );
            }
          },
          point: (point) async {
            final mp = point.originalPoint;
            final avatarUrl = avatarService.getAvatarUrlSync(mp.userId);
            final key = 'avatar_${mp.userId}_${avatarUrl?.hashCode ?? 0}';
            final bitmap =
                _bitmapCache[key] ??
                await _renderAvatarBitmap(avatarUrl, size: 100);
            if (bitmap != null) {
              _bitmapCache[key] = bitmap;
              options.add(
                PointAnnotationOptions(
                  geometry: Point(
                    coordinates: Position(mp.longitude, mp.latitude),
                  ),
                  image: bitmap,
                  iconSize: 1.0,
                ),
              );
              momentIdList.add(mp.momentId);
            }
          },
        );
      }

      // Wait a tick for async bitmap work to settle
      await Future.delayed(const Duration(milliseconds: 50));

      _log.i('Annotation options: ${options.length}');
      if (options.isNotEmpty && mounted) {
        final annotations = await _annotationManager!.createMulti(options);
        _log.i('Created annotations: ${annotations.length}');
        for (
          int i = 0;
          i < annotations.length && i < momentIdList.length;
          i++
        ) {
          final ann = annotations[i];
          if (ann != null) {
            _annotationMomentIds[ann.id] = momentIdList[i];
          }
        }
      }
    } catch (e) {
      _log.w('Failed to update annotations: $e');
    } finally {
      _updatingAnnotations = false;
    }
  }

  void _onAnnotationTapped(PointAnnotation annotation) {
    final id = _annotationMomentIds[annotation.id];
    if (id == null) return;

    // Otherwise, open moment details
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

  // ---------------------------------------------------------------------------
  // Bitmap rendering helpers
  // ---------------------------------------------------------------------------

  /// Render a single circle avatar bitmap from an avatar URL.
  Future<Uint8List?> _renderAvatarBitmap(
    String? avatarUrl, {
    double size = 100,
    double borderWidth = 3,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - borderWidth / 2,
        Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      final ui.Image? image = await _loadAvatarImage(avatarUrl);
      if (image != null) {
        final innerRadius = size / 2 - borderWidth - 1;
        canvas.save();
        canvas.clipPath(
          Path()..addOval(
            Rect.fromCircle(
              center: Offset(size / 2, size / 2),
              radius: innerRadius,
            ),
          ),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(
            center: Offset(size / 2, size / 2),
            radius: innerRadius,
          ),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        _drawDefaultAvatar(canvas, size, borderWidth);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Avatar bitmap render failed: $e');
      return null;
    }
  }

  Future<ui.Image?> _loadAvatarImage(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    final cached = _avatarImageCache[avatarUrl];
    if (cached != null) return cached;

    final future = () async {
      try {
        final imageProvider = CachedNetworkImageProvider(avatarUrl);
        final completer = Completer<ui.Image?>();
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener(
            (info, _) {
              if (!completer.isCompleted) completer.complete(info.image);
            },
            onError: (e, _) {
              if (!completer.isCompleted) completer.complete(null);
            },
          ),
        );

        return await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      } catch (_) {
        return null;
      }
    }();

    _avatarImageCache[avatarUrl] = future;
    return future;
  }

  void _drawDefaultAvatar(Canvas canvas, double size, double borderWidth) {
    final innerRadius = size / 2 - borderWidth - 1;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      innerRadius,
      Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.15),
    );
    // Draw person icon placeholder
    final iconPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;
    // Simple circle head
    canvas.drawCircle(Offset(size / 2, size / 2 - 3), 5, iconPaint);
    // Simple body arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size / 2, size / 2 + 10),
        width: 16,
        height: 12,
      ),
      3.14,
      3.14,
      true,
      iconPaint,
    );
  }

  List<String> _collectClusterUserIds(
    LayerCluster<_MomentPoint> cluster, {
    int limit = 3,
  }) {
    if (_cluster == null) return [];
    final userIds = <String>[];
    final pending = <LayerElement<_MomentPoint>>[];
    pending.addAll(_cluster!.childrenOf(cluster));

    while (pending.isNotEmpty && userIds.length < limit) {
      final element = pending.removeLast();
      element.handle(
        cluster: (c) => pending.addAll(_cluster!.childrenOf(c)),
        point: (p) {
          final userId = p.originalPoint.userId;
          if (userId.isNotEmpty && !userIds.contains(userId)) {
            userIds.add(userId);
          }
        },
      );
    }

    return userIds;
  }

  Future<Uint8List?> _renderClusterAvatarStack({
    required List<String> userIds,
    required AvatarCacheService avatarService,
  }) async {
    const double size = 100;
    const double borderWidth = 3;
    const double miniRadius = 16;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Match the single-avatar ring and size
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - borderWidth / 2,
        Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      final mainAvatarUrl = userIds.isNotEmpty
          ? avatarService.getAvatarUrlSync(userIds.first)
          : null;
      final mainImage = await _loadAvatarImage(mainAvatarUrl);
      if (mainImage != null) {
        final innerRadius = size / 2 - borderWidth - 1;
        canvas.save();
        canvas.clipPath(
          Path()..addOval(
            Rect.fromCircle(
              center: Offset(size / 2, size / 2),
              radius: innerRadius,
            ),
          ),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(
            center: Offset(size / 2, size / 2),
            radius: innerRadius,
          ),
          image: mainImage,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        _drawDefaultAvatar(canvas, size, borderWidth);
      }

      final miniOffsets = <Offset>[
        Offset(size * 0.26, size * 0.74),
        Offset(size * 0.74, size * 0.74),
      ];

      for (int i = 1; i < userIds.length && i - 1 < miniOffsets.length; i++) {
        final avatarUrl = avatarService.getAvatarUrlSync(userIds[i]);
        final image = await _loadAvatarImage(avatarUrl);
        final center = miniOffsets[i - 1];

        canvas.drawCircle(
          center,
          miniRadius + 2,
          Paint()..color = Colors.white,
        );

        if (image != null) {
          canvas.save();
          canvas.clipPath(
            Path()
              ..addOval(Rect.fromCircle(center: center, radius: miniRadius)),
          );
          paintImage(
            canvas: canvas,
            rect: Rect.fromCircle(center: center, radius: miniRadius),
            image: image,
            fit: BoxFit.cover,
          );
          canvas.restore();
        } else {
          canvas.drawCircle(
            center,
            miniRadius,
            Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.15),
          );
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Cluster avatar stack render failed: $e');
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

    await _initializeLocation();

    if (_currentPosition == null && mounted) {
      context.showErrorSnackBar('Unable to get current location');
      return false;
    }
    return true;
  }

  Future<void> _pickFromCamera({required String mediaType}) async {
    if (!await _ensureLocation()) return;

    try {
      final imagePicker = picker.ImagePicker();
      picker.XFile? file;

      if (mediaType == 'photo') {
        file = await imagePicker.pickImage(source: picker.ImageSource.camera);
      } else {
        file = await imagePicker.pickVideo(
          source: picker.ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file == null || !mounted) return;

      if (!await _ensureLocation()) return;

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
                : Point(
                    coordinates: Position(36.8219, -1.2921),
                  ), // Nairobi fallback
            zoom: mapUiState.camera?.zoom ?? 14.0,
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

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  _AnnotationClickListener(this.onTap);

  final void Function(PointAnnotation annotation) onTap;

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onTap(annotation);
    return true;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:wechat_assets_picker/wechat_assets_picker.dart'
    hide LatLng, RequestType;
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/signed_url_cache.dart';
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
import '../providers/map_control_provider.dart';
import '../widgets/moment_cards_carousel.dart';
import '../widgets/location_label.dart';
import '../utils/map_logic_service.dart';

final _log = AppLogger('MapPageV2');

const String _mapboxAccessToken =
    'pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg';

/// Map page V2 using native Mapbox GL with native clustering
/// and hybrid point markers for unclustered moments.
///
/// Key design decisions:
/// - Uses Mapbox native GeoJsonSource clustering + CircleLayer/SymbolLayer for
///   highly-performant cluster rendering.
/// - Uses PointAnnotationManager only for unclustered moments so each marker can
///   render a hybrid bitmap (group cover image + avatar badge).
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

  static const _momentsSourceId = 'moments-points';
  static const _clustersLayerId = 'moments-clusters';
  static const _clusterCountLayerId = 'moments-cluster-count';
  static const _unclusteredHitLayerId = 'moments-unclustered-hit';

  PointAnnotationManager? _annotationManager;
  final Map<String, Uint8List> _bitmapCache = {};

  // Avatar/Cover image caching (non-blocking)
  final Map<String, ui.Image> _loadedAvatars = {};
  final Set<String> _loadingAvatars = {};
  final Map<String, ui.Image> _loadedCoverImages = {};
  final Set<String> _loadingCoverImages = {};
  final Map<String, String> _resolvedCoverUrlsByPath = {};
  final Set<String> _resolvingCoverPaths = {};

  bool _updatingAnnotations = false;
  int _momentsHash = 0;
  int? _lastElementsHash;
  int? _lastZoomStep;
  Position? _lastAnnotationCenter;
  Position? _lastGroupCenter;
  late final _AnnotationClickListener _annotationClickListener;

  // Map annotation ID -> Moment/Cluster ID
  final Map<String, String> _annotationMomentIds = {};
  // Track current annotation IDs on the map to enable diffing
  final Set<String> _currentAnnotationIds = {};

  Timer? _locationPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapboxOptions.setAccessToken(_mapboxAccessToken);
    _annotationClickListener = _AnnotationClickListener(_onAnnotationTapped);

    ref.listenManual<latlong.LatLng?>(mapCameraTargetProvider, (
      previous,
      next,
    ) {
      if (next == null || !_isMapReady || _mapboxMap == null) return;

      unawaited(
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(next.longitude, next.latitude)),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        ),
      );

      ref.read(mapCameraTargetProvider.notifier).setTarget(null);
    }, fireImmediately: false);

    // Don't call _initializeLocation here — let Mapbox's puck handle the
    // permission dialog in _onStyleLoaded to avoid duplicate system prompts.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _annotationDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _locationPollTimer?.cancel();
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
      final location = Location();
      final permission = await location.hasPermission();

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

      final loc = await location.getLocation();
      if (mounted && loc.latitude != null && loc.longitude != null) {
        setState(() => _currentPosition = loc);
        await _maybeFlyToUserLocation();
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

  Future<void> _maybeFlyToUserLocation() async {
    final targetNotifier = ref.read(mapCameraTargetProvider.notifier);
    if (targetNotifier.skipNextLocationUpdate) {
      targetNotifier.clearSkipFlag();
      _log.i('Skipped auto-location flyTo because external camera target won');
      return;
    }

    await _flyToUserLocation();
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
      unawaited(_maybeFlyToUserLocation());
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
      await _maybeFlyToUserLocation();
    }

    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    _annotationManager?.addOnPointAnnotationClickListener(
      _annotationClickListener,
    );
    unawaited(_annotationManager?.setIconAllowOverlap(true));

    if (_allVisibleMoments.isNotEmpty) {
      await _syncClusterSource(_allVisibleMoments);
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
      _lastAnnotationCenter = cameraState.center.coordinates;
      return true;
    }

    if (_lastAnnotationCenter == null) {
      _lastAnnotationCenter = cameraState.center.coordinates;
      return true;
    }

    final center = cameraState.center.coordinates;
    final latDelta = (center.lat - _lastAnnotationCenter!.lat).abs();
    final lngDelta = (center.lng - _lastAnnotationCenter!.lng).abs();
    final shouldUpdate = latDelta >= 0.0008 || lngDelta >= 0.0008;
    if (shouldUpdate) {
      _lastAnnotationCenter = center;
    }

    return shouldUpdate;
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
    _log.i('Refresh native clusters for ${visibleMoments.length} moments');
    await _syncClusterSource(visibleMoments);
    await _updateAnnotations();
    await _updateVisibleGroups();

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
  // Native clustering + hybrid point markers
  // ---------------------------------------------------------------------------

  Future<void> _syncClusterSource(List<Moment> moments) async {
    if (_mapboxMap == null || !_isStyleLoaded) return;

    final validMoments = moments
        .where((m) => m.latitude != 0 && m.longitude != 0)
        .toList(growable: false);
    final geoJson = _buildMomentsGeoJson(validMoments);

    try {
      final style = _mapboxMap!.style;
      final sourceExists = await style.styleSourceExists(_momentsSourceId);
      if (!sourceExists) {
        await style.addSource(
          GeoJsonSource(
            id: _momentsSourceId,
            data: geoJson,
            cluster: true,
            clusterRadius: 50,
            clusterMaxZoom: 14,
            clusterMinPoints: 2,
          ),
        );
      } else {
        final source = await style.getSource(_momentsSourceId);
        if (source is GeoJsonSource) {
          await source.updateGeoJSON(geoJson);
        } else {
          _log.w('Unexpected source type for $_momentsSourceId');
        }
      }

      await _ensureClusterLayers();
    } catch (e) {
      _log.w('Failed to sync native cluster source: $e');
    }
  }

  Future<void> _ensureClusterLayers() async {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    if (!await style.styleLayerExists(_clustersLayerId)) {
      await style.addLayer(
        CircleLayer(
          id: _clustersLayerId,
          sourceId: _momentsSourceId,
          filter: ['has', 'point_count'],
          circleColorExpression: [
            'step',
            ['get', 'point_count'],
            '#51bbd6',
            100,
            '#f1f075',
            750,
            '#f28cb1',
          ],
          circleRadiusExpression: [
            'step',
            ['get', 'point_count'],
            20,
            100,
            30,
            750,
            40,
          ],
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 1.5,
          circleOpacity: 0.9,
        ),
      );
    }

    if (!await style.styleLayerExists(_clusterCountLayerId)) {
      await style.addLayer(
        SymbolLayer(
          id: _clusterCountLayerId,
          sourceId: _momentsSourceId,
          filter: ['has', 'point_count'],
          textField: '{point_count_abbreviated}',
          textSize: 12,
          textColor: Colors.white.toARGB32(),
          textHaloColor: Colors.black.withValues(alpha: 0.3).toARGB32(),
          textHaloWidth: 1.0,
        ),
      );
    }

    if (!await style.styleLayerExists(_unclusteredHitLayerId)) {
      await style.addLayer(
        CircleLayer(
          id: _unclusteredHitLayerId,
          sourceId: _momentsSourceId,
          filter: [
            '!',
            ['has', 'point_count'],
          ],
          circleRadius: 26,
          circleColor: Colors.white.toARGB32(),
          circleOpacity: 0.01,
        ),
      );
    }
  }

  String _buildMomentsGeoJson(List<Moment> moments) {
    final features = moments
        .map(
          (m) => {
            'type': 'Feature',
            'id': m.id,
            'properties': {
              'moment_id': m.id,
              'moment_group_id': m.momentGroupId,
              'user_id': m.userId ?? '',
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [m.longitude, m.latitude],
            },
          },
        )
        .toList(growable: false);

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  Future<void> _updateAnnotations() async {
    if (_mapboxMap == null ||
        _annotationManager == null ||
        _updatingAnnotations ||
        !_isStyleLoaded) {
      return;
    }

    _updatingAnnotations = true;

    try {
      if (!await _mapboxMap!.style.styleLayerExists(_unclusteredHitLayerId)) {
        return;
      }

      final viewport = MediaQuery.sizeOf(context);
      final rendered = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(x: 0, y: 0),
            max: ScreenCoordinate(x: viewport.width, y: viewport.height),
          ),
        ),
        RenderedQueryOptions(layerIds: [_unclusteredHitLayerId], filter: null),
      );

      final visibleMomentIds = <String>{};
      for (final item in rendered.whereType<QueriedRenderedFeature>()) {
        final feature = item.queriedFeature.feature;
        final properties = feature['properties'];
        if (properties is! Map) continue;

        final momentId = properties['moment_id']?.toString();
        if (momentId != null && momentId.isNotEmpty) {
          visibleMomentIds.add(momentId);
        }
      }

      final elementsHash = Object.hashAll(visibleMomentIds.toList()..sort());

      if (_lastElementsHash == elementsHash) {
        return;
      }
      _lastElementsHash = elementsHash;

      final momentsById = {for (final m in _allVisibleMoments) m.id: m};

      final futures = visibleMomentIds.map((momentId) async {
        final moment = momentsById[momentId];
        if (moment == null) return null;

        final markerAssetKey =
            '${moment.localMediaPath ?? ''}_${moment.localThumbnailPath ?? ''}_${moment.mediaPath ?? ''}_${moment.thumbnailPath ?? ''}_${moment.userId ?? ''}';
        final cacheKey = 'hybrid_${moment.id}_$markerAssetKey';

        final bitmap =
            _bitmapCache[cacheKey] ?? await _renderHybridMarkerBitmap(moment);
        if (bitmap == null) return null;

        _bitmapCache[cacheKey] = bitmap;
        return (
          id: 'p_${moment.id}',
          momentId: moment.id,
          options: PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(moment.longitude, moment.latitude),
            ),
            image: bitmap,
            iconSize: 1.0,
          ),
        );
      });

      final results = await Future.wait(futures);

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

      if (toDelete.isNotEmpty) {
        final currentAnns = await _annotationManager!.getAnnotations();
        final annsToDelete = currentAnns
            .where((a) => toDelete.contains(_getStableId(a)))
            .toList();

        if (annsToDelete.isNotEmpty) {
          await _annotationManager!.deleteMulti(annsToDelete);
          for (final ann in annsToDelete) {
            final stableId = _getStableId(ann);
            if (stableId != null && stableId.isNotEmpty) {
              _finalAnnotationMap.remove(stableId);
            }
            _annotationMomentIds.remove(ann.id);
          }
        }
      }

      if (toAdd.isNotEmpty) {
        final optionsToAdd = toAdd.map((id) => targetAnnotations[id]!).toList();
        if (optionsToAdd.isNotEmpty) {
          final newAnns = await _annotationManager!.createMulti(optionsToAdd);
          for (int i = 0; i < newAnns.length; i++) {
            final ann = newAnns[i];
            final id = toAdd[i];
            if (ann != null) {
              _finalAnnotationMap[id] = ann.id;
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
  final Map<String, String> _finalAnnotationMap = {};

  String? _getStableId(PointAnnotation ann) {
    return _finalAnnotationMap.keys.firstWhere(
      (k) => _finalAnnotationMap[k] == ann.id,
      orElse: () => '',
    );
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    if (_mapboxMap == null || !_isStyleLoaded) return;

    try {
      final clusterHits = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
        RenderedQueryOptions(layerIds: [_clustersLayerId], filter: null),
      );

      final firstCluster = clusterHits
          .whereType<QueriedRenderedFeature>()
          .firstOrNull;
      if (firstCluster == null) return;

      final clusterFeature = firstCluster.queriedFeature.feature;
      final expansion = await _mapboxMap!.getGeoJsonClusterExpansionZoom(
        _momentsSourceId,
        clusterFeature,
      );

      final geometry = clusterFeature['geometry'];
      if (geometry is! Map) return;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) return;

      final lng = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final expansionZoom = double.tryParse(expansion.value ?? '');
      final targetZoom = (expansionZoom ?? (_currentZoom + 1.5)).clamp(
        1.0,
        20.0,
      );

      await _mapboxMap!.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: targetZoom,
        ),
        MapAnimationOptions(duration: 320, startDelay: 0),
      );
    } catch (e) {
      _log.w('Cluster tap handling failed: $e');
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

  /// Render a hybrid marker: moment cover image as primary visual + avatar badge.
  Future<Uint8List?> _renderHybridMarkerBitmap(
    Moment moment, {
    double size = 106,
    double borderWidth = 3.5,
  }) async {
    try {
      const shadowPad = 10.0;
      const avatarSize = 34.0;
      final totalSize = size + shadowPad;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final center = Offset(totalSize / 2, totalSize / 2 - 1);

      // Drop shadow
      canvas.drawCircle(
        Offset(center.dx, center.dy + 4),
        size / 2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // White base + ring
      canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        size / 2 - borderWidth / 2,
        Paint()
          ..color = AppTheme.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );

      final coverImage = _loadMomentCoverImage(moment);
      final coverRadius = size / 2 - borderWidth - 1;
      if (coverImage != null) {
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: coverRadius)),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: center, radius: coverRadius),
          image: coverImage,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(
          center,
          coverRadius,
          Paint()..color = AppTheme.backgroundBeige,
        );
        final iconPainter = TextPainter(
          text: const TextSpan(
            text: 'M',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        iconPainter.paint(
          canvas,
          Offset(
            center.dx - iconPainter.width / 2,
            center.dy - iconPainter.height / 2,
          ),
        );
      }

      // Avatar badge (bottom-right)
      final badgeCenter = Offset(
        center.dx + size * 0.23,
        center.dy + size * 0.23,
      );
      final avatarRadius = avatarSize / 2;
      canvas.drawCircle(
        Offset(badgeCenter.dx, badgeCenter.dy + 1.5),
        avatarRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        badgeCenter,
        avatarRadius,
        Paint()..color = Colors.white,
      );

      final avatarImage = _loadAvatarImage(null, userId: moment.userId);
      final avatarInnerRadius = avatarRadius - 2.5;
      if (avatarImage != null) {
        canvas.save();
        canvas.clipPath(
          Path()..addOval(
            Rect.fromCircle(center: badgeCenter, radius: avatarInnerRadius),
          ),
        );
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: badgeCenter, radius: avatarInnerRadius),
          image: avatarImage,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(
          badgeCenter,
          avatarInnerRadius,
          Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.22),
        );
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.w('Hybrid marker render failed: $e');
      return null;
    }
  }

  ui.Image? _loadMomentCoverImage(Moment moment) {
    final localPath = moment.mediaType == 'video'
        ? (moment.localThumbnailPath ?? moment.localMediaPath)
        : moment.localMediaPath;

    if (localPath != null && localPath.isNotEmpty) {
      return _loadImageFromProvider(
        imageKey: 'cover_local:$localPath',
        provider: FileImage(File(localPath)),
        loadedMap: _loadedCoverImages,
        loadingSet: _loadingCoverImages,
      );
    }

    final remotePath = moment.mediaType == 'video'
        ? (moment.thumbnailPath ?? moment.mediaPath)
        : moment.mediaPath;
    if (remotePath == null || remotePath.isEmpty) return null;

    final resolvedUrl = _resolvedCoverUrlsByPath[remotePath];
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (!_resolvingCoverPaths.contains(remotePath)) {
        _resolvingCoverPaths.add(remotePath);
        unawaited(
          SignedUrlCache.getSignedUrl(remotePath).then((url) {
            if (!mounted) return;
            setState(() {
              _resolvingCoverPaths.remove(remotePath);
              if (url != null && url.isNotEmpty) {
                _resolvedCoverUrlsByPath[remotePath] = url;
              }
            });
            _invalidateMarkerCaches();
          }),
        );
      }
      return null;
    }

    return _loadImageFromProvider(
      imageKey: 'cover_remote:$resolvedUrl',
      provider: CachedNetworkImageProvider(resolvedUrl),
      loadedMap: _loadedCoverImages,
      loadingSet: _loadingCoverImages,
    );
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

    final provider =
        avatarService.getAvatarImageProvider(resolvedUrl) ??
        CachedNetworkImageProvider(resolvedUrl);
    return _loadImageFromProvider(
      imageKey: 'avatar:$resolvedUrl',
      provider: provider,
      loadedMap: _loadedAvatars,
      loadingSet: _loadingAvatars,
    );
  }

  ui.Image? _loadImageFromProvider({
    required String imageKey,
    required ImageProvider provider,
    required Map<String, ui.Image> loadedMap,
    required Set<String> loadingSet,
  }) {
    final existing = loadedMap[imageKey];
    if (existing != null) return existing;

    if (loadingSet.contains(imageKey)) return null;
    loadingSet.add(imageKey);

    provider
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener(
            (info, _) {
              if (!mounted) return;
              setState(() {
                loadedMap[imageKey] = info.image;
                loadingSet.remove(imageKey);
              });
              _invalidateMarkerCaches();
            },
            onError: (_, __) {
              if (!mounted) return;
              setState(() {
                loadingSet.remove(imageKey);
              });
            },
          ),
        );

    return null;
  }

  void _invalidateMarkerCaches() {
    if (!mounted) return;
    setState(() {
      _bitmapCache.clear();
      _lastElementsHash = null;
    });

    if (!_updatingAnnotations && _mapboxMap != null) {
      _mapboxMap!.getCameraState().then((cam) {
        if (mounted) _scheduleViewportUpdate(cam);
      });
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
    if (!await _ensureLocation()) return;
    if (!mounted) return;

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
    if (!mounted) return;

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
          onTapListener: _onMapTap,
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

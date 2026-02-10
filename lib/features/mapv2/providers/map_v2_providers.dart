import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong2;

/// Holds the selected moment group index in the bottom carousel.
/// Separated from the map page state so widgets can read it independently.
final selectedGroupIndexProvider = Provider<int>((ref) => 0);

/// Whether the V2 map page is active (for feature flagging / A-B switch).
final useMapV2Provider = Provider<bool>((ref) => true);

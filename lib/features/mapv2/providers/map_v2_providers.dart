import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the map style preference.
const _mapStyleKey = 'map_style_v2_enabled';

/// SharedPreferences key to track if user has seen the map picker.
const mapStylePickerSeenKey = 'map_style_picker_seen';

/// Holds the selected moment group index in the bottom carousel.
/// Separated from the map page state so widgets can read it independently.
final selectedGroupIndexProvider = Provider<int>((ref) => 0);

/// Whether the V2 map page is active (native Mapbox vs flutter_map).
/// Backed by SharedPreferences so the choice persists across restarts.
/// Defaults to true (Mapbox native) until prefs are loaded.
final useMapV2Provider = NotifierProvider<MapStyleNotifier, bool>(
  MapStyleNotifier.new,
);

/// Notifier for the map style preference.
class MapStyleNotifier extends Notifier<bool> {
  @override
  bool build() => true; // default until prefs load

  void set(bool value) {
    state = value;
  }
}

/// Helper class for map style SharedPreferences operations.
class MapStylePrefs {
  /// Load the saved preference and update the provider.
  static Future<void> loadInto(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final useV2 = prefs.getBool(_mapStyleKey) ?? true;
    ref.read(useMapV2Provider.notifier).set(useV2);
  }

  /// Save the preference and update the provider.
  static Future<void> setUseV2(WidgetRef ref, bool value) async {
    ref.read(useMapV2Provider.notifier).set(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mapStyleKey, value);
  }

  /// Check if the user has already seen the map style picker.
  static Future<bool> hasSeenPicker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(mapStylePickerSeenKey) ?? false;
  }

  /// Mark the map style picker as seen.
  static Future<void> markPickerSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(mapStylePickerSeenKey, true);
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'offline_media_policy_service.g.dart';

enum OfflineMediaMode { smart, always, never }

class OfflineMediaPolicy {
  final OfflineMediaMode mode;
  final bool wifiOnly;
  final int maxCacheMb;
  final Set<String> pinnedMomentIds;
  final Set<String> pinnedGroupIds;

  const OfflineMediaPolicy({
    required this.mode,
    required this.wifiOnly,
    required this.maxCacheMb,
    required this.pinnedMomentIds,
    required this.pinnedGroupIds,
  });
}

@Riverpod(keepAlive: true)
OfflineMediaPolicyService offlineMediaPolicyService(Ref ref) {
  return OfflineMediaPolicyService();
}

/// Controls offline media retention strategy independently from PowerSync row sync.
class OfflineMediaPolicyService {
  static const _modeKey = 'offline_media.mode';
  static const _wifiOnlyKey = 'offline_media.wifi_only';
  static const _maxCacheMbKey = 'offline_media.max_cache_mb';
  static const _pinnedMomentsKey = 'offline_media.pinned_moments';
  static const _pinnedGroupsKey = 'offline_media.pinned_groups';

  SharedPreferences? _prefs;
  Future<void>? _initialization;

  bool get isInitialized => _prefs != null;

  Future<void> initialize() {
    _initialization ??= _initializeInternal();
    return _initialization!;
  }

  Future<void> _initializeInternal() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs != null) return;
    await initialize();
  }

  Future<OfflineMediaPolicy> getPolicy() async {
    await _ensureInitialized();
    final prefs = _prefs!;

    return OfflineMediaPolicy(
      mode: _readMode(prefs),
      wifiOnly: prefs.getBool(_wifiOnlyKey) ?? true,
      maxCacheMb: prefs.getInt(_maxCacheMbKey) ?? 500,
      pinnedMomentIds: prefs.getStringList(_pinnedMomentsKey)?.toSet() ?? {},
      pinnedGroupIds: prefs.getStringList(_pinnedGroupsKey)?.toSet() ?? {},
    );
  }

  Future<OfflineMediaMode> getMode() async {
    await _ensureInitialized();
    return _readMode(_prefs!);
  }

  Future<void> setMode(OfflineMediaMode mode) async {
    await _ensureInitialized();
    await _prefs!.setString(_modeKey, mode.name);
  }

  Future<bool> getWifiOnly() async {
    await _ensureInitialized();
    return _prefs!.getBool(_wifiOnlyKey) ?? true;
  }

  Future<void> setWifiOnly(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_wifiOnlyKey, value);
  }

  Future<int> getMaxCacheMb() async {
    await _ensureInitialized();
    return _prefs!.getInt(_maxCacheMbKey) ?? 500;
  }

  Future<void> setMaxCacheMb(int value) async {
    await _ensureInitialized();
    await _prefs!.setInt(_maxCacheMbKey, value);
  }

  Future<void> setMomentPinned(String momentId, bool pinned) async {
    await _ensureInitialized();
    final values = _prefs!.getStringList(_pinnedMomentsKey)?.toSet() ?? {};
    if (pinned) {
      values.add(momentId);
    } else {
      values.remove(momentId);
    }
    await _prefs!.setStringList(_pinnedMomentsKey, values.toList());
  }

  Future<bool> isMomentPinned(String momentId) async {
    await _ensureInitialized();
    final values = _prefs!.getStringList(_pinnedMomentsKey) ?? const [];
    return values.contains(momentId);
  }

  Future<void> setGroupPinned(String groupId, bool pinned) async {
    await _ensureInitialized();
    final values = _prefs!.getStringList(_pinnedGroupsKey)?.toSet() ?? {};
    if (pinned) {
      values.add(groupId);
    } else {
      values.remove(groupId);
    }
    await _prefs!.setStringList(_pinnedGroupsKey, values.toList());
  }

  Future<bool> isGroupPinned(String groupId) async {
    await _ensureInitialized();
    final values = _prefs!.getStringList(_pinnedGroupsKey) ?? const [];
    return values.contains(groupId);
  }

  Future<Set<String>> getPinnedMomentIds() async {
    await _ensureInitialized();
    return _prefs!.getStringList(_pinnedMomentsKey)?.toSet() ?? {};
  }

  Future<Set<String>> getPinnedGroupIds() async {
    await _ensureInitialized();
    return _prefs!.getStringList(_pinnedGroupsKey)?.toSet() ?? {};
  }

  /// Suggested policy helper for media retention decisions.
  Future<bool> shouldCacheMedia({
    String? momentId,
    String? groupId,
    bool isOwnMoment = false,
    bool recentlyViewed = false,
  }) async {
    final policy = await getPolicy();

    final pinnedById =
        (momentId != null && policy.pinnedMomentIds.contains(momentId)) ||
        (groupId != null && policy.pinnedGroupIds.contains(groupId));

    if (pinnedById) return true;

    switch (policy.mode) {
      case OfflineMediaMode.always:
        return true;
      case OfflineMediaMode.never:
        return false;
      case OfflineMediaMode.smart:
        return isOwnMoment || recentlyViewed;
    }
  }

  Future<void> clearPins() async {
    await _ensureInitialized();
    await _prefs!.remove(_pinnedMomentsKey);
    await _prefs!.remove(_pinnedGroupsKey);
  }

  OfflineMediaMode _readMode(SharedPreferences prefs) {
    final raw = prefs.getString(_modeKey);
    return OfflineMediaMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => OfflineMediaMode.smart,
    );
  }
}

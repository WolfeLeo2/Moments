import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

/// Recent error cutoff duration - used across sync status checks
const _recentErrorCutoff = Duration(minutes: 5);

/// Represents a sync error from any source
class SyncError {
  final String source; // e.g., 'chat', 'moments', 'notifications'
  final String message;
  final DateTime timestamp;
  final String? details;

  const SyncError({
    required this.source,
    required this.message,
    required this.timestamp,
    this.details,
  });
}

/// Sync status enum
enum SyncStatus {
  synced, // All good
  syncing, // Currently syncing
  error, // Has errors
  offline, // No connection
}

/// Global sync state provider
/// Tracks sync errors from various sources and provides overall status
@Riverpod(keepAlive: true)
class SyncState extends _$SyncState {
  @override
  List<SyncError> build() => [];

  /// Add a sync error
  void addError(String source, String message, {String? details}) {
    state = [
      ...state,
      SyncError(
        source: source,
        message: message,
        timestamp: DateTime.now(),
        details: details,
      ),
    ];
    // Keep only last 50 errors
    if (state.length > 50) {
      state = state.sublist(state.length - 50);
    }
  }

  /// Clear errors for a specific source
  void clearErrors(String source) {
    state = state.where((e) => e.source != source).toList();
  }

  /// Clear all errors
  void clearAll() {
    state = [];
  }

  /// Get errors grouped by source
  Map<String, List<SyncError>> get errorsBySource {
    final map = <String, List<SyncError>>{};
    for (final error in state) {
      map.putIfAbsent(error.source, () => []).add(error);
    }
    return map;
  }
}

/// Convenience provider for just the status
@riverpod
SyncStatus syncStatus(Ref ref) {
  final errors = ref.watch(syncStateProvider);
  if (errors.isEmpty) return SyncStatus.synced;
  final recentCutoff = DateTime.now().subtract(_recentErrorCutoff);
  final hasRecentErrors = errors.any((e) => e.timestamp.isAfter(recentCutoff));
  return hasRecentErrors ? SyncStatus.error : SyncStatus.synced;
}

/// Error count provider
@riverpod
int syncErrorCount(Ref ref) {
  return ref.watch(syncStateProvider).length;
}


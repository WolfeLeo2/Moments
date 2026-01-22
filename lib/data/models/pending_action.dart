import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Types of actions that can be queued for offline sync
enum PendingActionType {
  deleteMoment,
  toggleMomentPrivacy,
  toggleGroupPrivacy,
  addReaction,
  removeReaction,
  editMessage,
  deleteMessage,
}

/// Priority levels for action processing
enum ActionPriority {
  high, // Deletes, privacy changes
  medium, // Reactions, edits
  low, // Read receipts
}

/// Represents a pending action to be synced when online
class PendingAction extends Equatable {
  final String id;
  final PendingActionType actionType;
  final String entityType; // 'moment', 'moment_group', 'message'
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime createdAt; // Always stored as UTC
  final int retryCount;
  final String? lastError;
  final ActionPriority priority;

  const PendingAction({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.priority = ActionPriority.medium,
  });

  /// Create from SQLite row
  /// SQLite stores timestamps as ISO 8601 UTC strings
  factory PendingAction.fromRow(Map<String, dynamic> row) {
    return PendingAction(
      id: row['id'] as String,
      actionType: PendingActionType.values.firstWhere(
        (e) => e.name == row['action_type'],
      ),
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      payload: row['payload'] != null
          ? jsonDecode(row['payload'] as String) as Map<String, dynamic>
          : null,
      // Parse ISO 8601 string back to DateTime (always UTC)
      createdAt: DateTime.parse(row['created_at'] as String),
      retryCount: row['retry_count'] as int? ?? 0,
      lastError: row['last_error'] as String?,
      priority: ActionPriority.values.firstWhere(
        (e) => e.name == (row['priority'] as String? ?? 'medium'),
        orElse: () => ActionPriority.medium,
      ),
    );
  }

  /// Convert to SQLite row
  /// Timestamps are stored as ISO 8601 UTC strings for Supabase compatibility
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'action_type': actionType.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload != null ? jsonEncode(payload) : null,
      // Store as ISO 8601 UTC string (Supabase timestamptz compatible)
      'created_at': createdAt.toUtc().toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
      'priority': priority.name,
    };
  }

  /// Create copy with updated fields
  PendingAction copyWith({
    String? id,
    PendingActionType? actionType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    ActionPriority? priority,
  }) {
    return PendingAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
    id,
    actionType,
    entityType,
    entityId,
    payload,
    createdAt,
    retryCount,
    lastError,
    priority,
  ];
}

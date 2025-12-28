import 'package:equatable/equatable.dart';
import 'moment.dart';

/// Shared location group where multiple users can contribute moments
/// This can be used for both local grouping (UI) and database-backed shared groups
class MomentGroup extends Equatable {
  final String id;
  final String title;
  final List<Moment> moments; // For UI grouping
  final double latitude;
  final double longitude;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate; // Group-level privacy

  const MomentGroup({
    required this.id,
    required this.title,
    required this.moments,
    required this.latitude,
    required this.longitude,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPrivate = false,
  });

  // Alias for title
  String get placeName => title;

  int get momentCount => moments.length;

  List<String> get imageUrls =>
      moments.where((m) => m.imageUrl != null).map((m) => m.imageUrl!).toList();

  List<String> get contributorIds => moments
      .where((m) => m.userId != null)
      .map((m) => m.userId!)
      .toSet()
      .toList();

  String get dateRange {
    if (moments.isEmpty) return '';

    final dates = moments.map((m) => m.createdAt).toList()..sort();
    final first = dates.first;
    final last = dates.last;

    return _formatDateRange(first, last);
  }

  String _formatDateRange(DateTime first, DateTime last) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (first.year == last.year &&
        first.month == last.month &&
        first.day == last.day) {
      return '${months[first.month - 1]} ${first.day}, ${first.year}';
    }

    return '${months[first.month - 1]} ${first.day} - ${months[last.month - 1]} ${last.day}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    moments,
    latitude,
    longitude,
    createdBy,
    createdAt,
    updatedAt,
    isPrivate,
  ];

  // Factory from database JSON (for server-side groups)
  factory MomentGroup.fromJson(Map<String, dynamic> json) {
    return MomentGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      moments: [], // Will be populated separately
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['created_at'] as String,
      ),
      isPrivate: json['is_private'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_private': isPrivate,
    };
  }

  MomentGroup copyWith({
    String? id,
    String? title,
    List<Moment>? moments,
    double? latitude,
    double? longitude,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
  }) {
    return MomentGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      moments: moments ?? this.moments,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

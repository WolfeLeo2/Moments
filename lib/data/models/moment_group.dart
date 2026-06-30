import 'package:freezed_annotation/freezed_annotation.dart';
import 'moment.dart';

part 'moment_group.freezed.dart';

@freezed
abstract class MomentGroup with _$MomentGroup {
  const MomentGroup._();

  const factory MomentGroup({
    required String id,
    required String title,
    /// Populated after construction — excluded from JSON serialization.
    @Default([]) List<Moment> moments,
    required double latitude,
    required double longitude,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isPrivate,
  }) = _MomentGroup;

  factory MomentGroup.fromJson(Map<String, dynamic> json) {
    return MomentGroup(
      id: json['id'] as String,
      title: json['title'] as String,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'latitude': latitude,
    'longitude': longitude,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_private': isPrivate,
  };

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
    return _formatDateRange(dates.first, dates.last);
  }

  static String _formatDateRange(DateTime first, DateTime last) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (first.year == last.year &&
        first.month == last.month &&
        first.day == last.day) {
      return '${months[first.month - 1]} ${first.day}, ${first.year}';
    }
    return '${months[first.month - 1]} ${first.day} – ${months[last.month - 1]} ${last.day}';
  }
}

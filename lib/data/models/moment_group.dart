import 'package:equatable/equatable.dart';
import 'moment.dart';

class MomentGroup extends Equatable {
  final String id;
  final String title;
  final List<Moment> moments;
  final double centerLatitude;
  final double centerLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MomentGroup({
    required this.id,
    required this.title,
    required this.moments,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.createdAt,
    required this.updatedAt,
  });

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
    centerLatitude,
    centerLongitude,
    createdAt,
    updatedAt,
  ];
}

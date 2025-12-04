import 'package:equatable/equatable.dart';

class PlaceGroup extends Equatable {
  final String id;
  final String title;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaceGroup({
    required this.id,
    required this.title,
    required this.centerLatitude,
    required this.centerLongitude,
    this.radiusMeters = 100.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaceGroup.fromJson(Map<String, dynamic> json) {
    return PlaceGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_meters': radiusMeters,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    return json;
  }

  PlaceGroup copyWith({
    String? id,
    String? title,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaceGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    centerLatitude,
    centerLongitude,
    radiusMeters,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'PlaceGroup(id: $id, title: $title, lat: $centerLatitude, lng: $centerLongitude)';
  }
}

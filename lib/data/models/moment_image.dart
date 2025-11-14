import 'package:equatable/equatable.dart';

class MomentImage extends Equatable {
  final String id;
  final String momentId;
  final String? imageUrl; // Nullable for backward compatibility
  final String mediaPath; // Required for new approach
  final String? caption;
  final int displayOrder;
  final DateTime createdAt;

  const MomentImage({
    required this.id,
    required this.momentId,
    this.imageUrl,
    required this.mediaPath,
    this.caption,
    required this.displayOrder,
    required this.createdAt,
  });

  factory MomentImage.fromJson(Map<String, dynamic> json) {
    return MomentImage(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      imageUrl: json['image_url'] as String?,
      mediaPath: json['media_path'] as String,
      caption: json['caption'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moment_id': momentId,
      'image_url': imageUrl,
      'media_path': mediaPath,
      'caption': caption,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    momentId,
    imageUrl,
    mediaPath,
    caption,
    displayOrder,
    createdAt,
  ];
}

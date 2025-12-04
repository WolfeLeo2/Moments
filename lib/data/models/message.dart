import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Message type enum
enum MessageType {
  text,
  image,
  audio,
  video,
  file;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Chat message model
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType messageType;
  final String? mediaUrl;
  final String? localMediaPath;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.localMediaPath,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse metadata - it could be null, a Map, or a JSON string
    Map<String, dynamic>? parsedMetadata;
    final rawMetadata = json['metadata'];
    if (rawMetadata != null) {
      if (rawMetadata is Map<String, dynamic>) {
        parsedMetadata = rawMetadata;
      } else if (rawMetadata is Map) {
        parsedMetadata = Map<String, dynamic>.from(rawMetadata);
      } else if (rawMetadata is String && rawMetadata.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawMetadata);
          if (decoded is Map) {
            parsedMetadata = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Ignore JSON decode errors
        }
      }
    }

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: MessageType.fromString(json['message_type'] as String),
      mediaUrl: json['media_url'] as String?,
      localMediaPath: json['local_media_path'] as String?,
      metadata: parsedMetadata,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.name,
      'media_url': mediaUrl,
      'local_media_path': localMediaPath,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'is_read': isRead,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? messageType,
    String? mediaUrl,
    String? localMediaPath,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    messageType,
    mediaUrl,
    localMediaPath,
    metadata,
    createdAt,
    updatedAt,
    isDeleted,
    isRead,
  ];
}

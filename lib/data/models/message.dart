import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:moments/data/models/reaction.dart';

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

/// Message send status for offline-first support
enum MessageSendStatus {
  /// Message created locally, not yet sent
  pending,
  
  /// Message is being sent to server
  sending,
  
  /// Message sent to server successfully
  sent,
  
  /// Message delivered to recipient's device
  delivered,
  
  /// Message read by recipient
  read,
  
  /// Message failed to send
  failed;

  static MessageSendStatus fromString(String? value) {
    if (value == null) return MessageSendStatus.sent;
    return MessageSendStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageSendStatus.sent,
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
  // New fields for replies and editing
  final String? replyToMessageId;
  final Message? replyToMessage; // Nested reply data (not from DB)
  final bool isEdited;
  final String? deletedFor; // null, 'self', or 'everyone'
  final List<Reaction> reactions; // Message reactions
  
  // Offline-first fields
  final MessageSendStatus sendStatus; // Current send status
  final bool localOnly; // True if message hasn't synced to server yet
  final DateTime? deliveredAt; // When message was delivered to recipient

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
    this.replyToMessageId,
    this.replyToMessage,
    this.isEdited = false,
    this.deletedFor,
    this.reactions = const [],
    this.sendStatus = MessageSendStatus.sent,
    this.localOnly = false,
    this.deliveredAt,
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
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? Message.fromJson(json['reply_to_message'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      deletedFor: json['deleted_for'] as String?,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sendStatus: MessageSendStatus.fromString(json['send_status'] as String?),
      localOnly: json['local_only'] as bool? ?? false,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String).toLocal()
          : null,
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
      'reply_to_message_id': replyToMessageId,
      'is_edited': isEdited,
      'deleted_for': deletedFor,
      'send_status': sendStatus.name,
      'local_only': localOnly,
      'delivered_at': deliveredAt?.toIso8601String(),
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
    String? replyToMessageId,
    Message? replyToMessage,
    bool? isEdited,
    String? deletedFor,
    List<Reaction>? reactions,
    MessageSendStatus? sendStatus,
    bool? localOnly,
    DateTime? deliveredAt,
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
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isEdited: isEdited ?? this.isEdited,
      deletedFor: deletedFor ?? this.deletedFor,
      reactions: reactions ?? this.reactions,
      sendStatus: sendStatus ?? this.sendStatus,
      localOnly: localOnly ?? this.localOnly,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
    replyToMessageId,
    replyToMessage,
    isEdited,
    deletedFor,
    reactions,
    sendStatus,
    localOnly,
    deliveredAt,
  ];
}

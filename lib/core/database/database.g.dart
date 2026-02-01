// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToContentMeta = const VerificationMeta(
    'replyToContent',
  );
  @override
  late final GeneratedColumn<String> replyToContent = GeneratedColumn<String>(
    'reply_to_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replySenderNameMeta = const VerificationMeta(
    'replySenderName',
  );
  @override
  late final GeneratedColumn<String> replySenderName = GeneratedColumn<String>(
    'reply_sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reactionsMeta = const VerificationMeta(
    'reactions',
  );
  @override
  late final GeneratedColumn<String> reactions = GeneratedColumn<String>(
    'reactions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedForMeta = const VerificationMeta(
    'deletedFor',
  );
  @override
  late final GeneratedColumn<String> deletedFor = GeneratedColumn<String>(
    'deleted_for',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEditedMeta = const VerificationMeta(
    'isEdited',
  );
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
    'is_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    content,
    messageType,
    mediaUrl,
    metadata,
    createdAt,
    isRead,
    isDeleted,
    replyToMessageId,
    replyToContent,
    replySenderName,
    reactions,
    deletedFor,
    isEdited,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_content')) {
      context.handle(
        _replyToContentMeta,
        replyToContent.isAcceptableOrUnknown(
          data['reply_to_content']!,
          _replyToContentMeta,
        ),
      );
    }
    if (data.containsKey('reply_sender_name')) {
      context.handle(
        _replySenderNameMeta,
        replySenderName.isAcceptableOrUnknown(
          data['reply_sender_name']!,
          _replySenderNameMeta,
        ),
      );
    }
    if (data.containsKey('reactions')) {
      context.handle(
        _reactionsMeta,
        reactions.isAcceptableOrUnknown(data['reactions']!, _reactionsMeta),
      );
    }
    if (data.containsKey('deleted_for')) {
      context.handle(
        _deletedForMeta,
        deletedFor.isAcceptableOrUnknown(data['deleted_for']!, _deletedForMeta),
      );
    }
    if (data.containsKey('is_edited')) {
      context.handle(
        _isEditedMeta,
        isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_type'],
      )!,
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      replyToContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_content'],
      ),
      replySenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_sender_name'],
      ),
      reactions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reactions'],
      ),
      deletedFor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_for'],
      ),
      isEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_edited'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageEntry extends DataClass implements Insertable<MessageEntry> {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final String? mediaUrl;
  final String? metadata;
  final int createdAt;
  final bool isRead;
  final bool isDeleted;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replySenderName;
  final String? reactions;
  final String? deletedFor;
  final bool isEdited;
  const MessageEntry({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.metadata,
    required this.createdAt,
    required this.isRead,
    required this.isDeleted,
    this.replyToMessageId,
    this.replyToContent,
    this.replySenderName,
    this.reactions,
    this.deletedFor,
    required this.isEdited,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['message_type'] = Variable<String>(messageType);
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['is_read'] = Variable<bool>(isRead);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    if (!nullToAbsent || replyToContent != null) {
      map['reply_to_content'] = Variable<String>(replyToContent);
    }
    if (!nullToAbsent || replySenderName != null) {
      map['reply_sender_name'] = Variable<String>(replySenderName);
    }
    if (!nullToAbsent || reactions != null) {
      map['reactions'] = Variable<String>(reactions);
    }
    if (!nullToAbsent || deletedFor != null) {
      map['deleted_for'] = Variable<String>(deletedFor);
    }
    map['is_edited'] = Variable<bool>(isEdited);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      content: Value(content),
      messageType: Value(messageType),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      isRead: Value(isRead),
      isDeleted: Value(isDeleted),
      replyToMessageId: replyToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToMessageId),
      replyToContent: replyToContent == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToContent),
      replySenderName: replySenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(replySenderName),
      reactions: reactions == null && nullToAbsent
          ? const Value.absent()
          : Value(reactions),
      deletedFor: deletedFor == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedFor),
      isEdited: Value(isEdited),
    );
  }

  factory MessageEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageEntry(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      messageType: serializer.fromJson<String>(json['messageType']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      replyToContent: serializer.fromJson<String?>(json['replyToContent']),
      replySenderName: serializer.fromJson<String?>(json['replySenderName']),
      reactions: serializer.fromJson<String?>(json['reactions']),
      deletedFor: serializer.fromJson<String?>(json['deletedFor']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'messageType': serializer.toJson<String>(messageType),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<int>(createdAt),
      'isRead': serializer.toJson<bool>(isRead),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'replyToContent': serializer.toJson<String?>(replyToContent),
      'replySenderName': serializer.toJson<String?>(replySenderName),
      'reactions': serializer.toJson<String?>(reactions),
      'deletedFor': serializer.toJson<String?>(deletedFor),
      'isEdited': serializer.toJson<bool>(isEdited),
    };
  }

  MessageEntry copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? messageType,
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    int? createdAt,
    bool? isRead,
    bool? isDeleted,
    Value<String?> replyToMessageId = const Value.absent(),
    Value<String?> replyToContent = const Value.absent(),
    Value<String?> replySenderName = const Value.absent(),
    Value<String?> reactions = const Value.absent(),
    Value<String?> deletedFor = const Value.absent(),
    bool? isEdited,
  }) => MessageEntry(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    messageType: messageType ?? this.messageType,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    isRead: isRead ?? this.isRead,
    isDeleted: isDeleted ?? this.isDeleted,
    replyToMessageId: replyToMessageId.present
        ? replyToMessageId.value
        : this.replyToMessageId,
    replyToContent: replyToContent.present
        ? replyToContent.value
        : this.replyToContent,
    replySenderName: replySenderName.present
        ? replySenderName.value
        : this.replySenderName,
    reactions: reactions.present ? reactions.value : this.reactions,
    deletedFor: deletedFor.present ? deletedFor.value : this.deletedFor,
    isEdited: isEdited ?? this.isEdited,
  );
  MessageEntry copyWithCompanion(MessagesCompanion data) {
    return MessageEntry(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      replyToContent: data.replyToContent.present
          ? data.replyToContent.value
          : this.replyToContent,
      replySenderName: data.replySenderName.present
          ? data.replySenderName.value
          : this.replySenderName,
      reactions: data.reactions.present ? data.reactions.value : this.reactions,
      deletedFor: data.deletedFor.present
          ? data.deletedFor.value
          : this.deletedFor,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageEntry(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('replyToContent: $replyToContent, ')
          ..write('replySenderName: $replySenderName, ')
          ..write('reactions: $reactions, ')
          ..write('deletedFor: $deletedFor, ')
          ..write('isEdited: $isEdited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    content,
    messageType,
    mediaUrl,
    metadata,
    createdAt,
    isRead,
    isDeleted,
    replyToMessageId,
    replyToContent,
    replySenderName,
    reactions,
    deletedFor,
    isEdited,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageEntry &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.messageType == this.messageType &&
          other.mediaUrl == this.mediaUrl &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.isRead == this.isRead &&
          other.isDeleted == this.isDeleted &&
          other.replyToMessageId == this.replyToMessageId &&
          other.replyToContent == this.replyToContent &&
          other.replySenderName == this.replySenderName &&
          other.reactions == this.reactions &&
          other.deletedFor == this.deletedFor &&
          other.isEdited == this.isEdited);
}

class MessagesCompanion extends UpdateCompanion<MessageEntry> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<String> messageType;
  final Value<String?> mediaUrl;
  final Value<String?> metadata;
  final Value<int> createdAt;
  final Value<bool> isRead;
  final Value<bool> isDeleted;
  final Value<String?> replyToMessageId;
  final Value<String?> replyToContent;
  final Value<String?> replySenderName;
  final Value<String?> reactions;
  final Value<String?> deletedFor;
  final Value<bool> isEdited;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.replyToContent = const Value.absent(),
    this.replySenderName = const Value.absent(),
    this.reactions = const Value.absent(),
    this.deletedFor = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    this.messageType = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.metadata = const Value.absent(),
    required int createdAt,
    this.isRead = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.replyToContent = const Value.absent(),
    this.replySenderName = const Value.absent(),
    this.reactions = const Value.absent(),
    this.deletedFor = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<MessageEntry> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<String>? messageType,
    Expression<String>? mediaUrl,
    Expression<String>? metadata,
    Expression<int>? createdAt,
    Expression<bool>? isRead,
    Expression<bool>? isDeleted,
    Expression<String>? replyToMessageId,
    Expression<String>? replyToContent,
    Expression<String>? replySenderName,
    Expression<String>? reactions,
    Expression<String>? deletedFor,
    Expression<bool>? isEdited,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (messageType != null) 'message_type': messageType,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (isRead != null) 'is_read': isRead,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
      if (replySenderName != null) 'reply_sender_name': replySenderName,
      if (reactions != null) 'reactions': reactions,
      if (deletedFor != null) 'deleted_for': deletedFor,
      if (isEdited != null) 'is_edited': isEdited,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<String>? content,
    Value<String>? messageType,
    Value<String?>? mediaUrl,
    Value<String?>? metadata,
    Value<int>? createdAt,
    Value<bool>? isRead,
    Value<bool>? isDeleted,
    Value<String?>? replyToMessageId,
    Value<String?>? replyToContent,
    Value<String?>? replySenderName,
    Value<String?>? reactions,
    Value<String?>? deletedFor,
    Value<bool>? isEdited,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replySenderName: replySenderName ?? this.replySenderName,
      reactions: reactions ?? this.reactions,
      deletedFor: deletedFor ?? this.deletedFor,
      isEdited: isEdited ?? this.isEdited,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (replyToContent.present) {
      map['reply_to_content'] = Variable<String>(replyToContent.value);
    }
    if (replySenderName.present) {
      map['reply_sender_name'] = Variable<String>(replySenderName.value);
    }
    if (reactions.present) {
      map['reactions'] = Variable<String>(reactions.value);
    }
    if (deletedFor.present) {
      map['deleted_for'] = Variable<String>(deletedFor.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('replyToContent: $replyToContent, ')
          ..write('replySenderName: $replySenderName, ')
          ..write('reactions: $reactions, ')
          ..write('deletedFor: $deletedFor, ')
          ..write('isEdited: $isEdited, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [friendId, conversationId, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {friendId};
  @override
  ConversationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationEntry(
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationEntry extends DataClass
    implements Insertable<ConversationEntry> {
  final String friendId;
  final String conversationId;
  final int cachedAt;
  const ConversationEntry({
    required this.friendId,
    required this.conversationId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['friend_id'] = Variable<String>(friendId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      friendId: Value(friendId),
      conversationId: Value(conversationId),
      cachedAt: Value(cachedAt),
    );
  }

  factory ConversationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationEntry(
      friendId: serializer.fromJson<String>(json['friendId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'friendId': serializer.toJson<String>(friendId),
      'conversationId': serializer.toJson<String>(conversationId),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  ConversationEntry copyWith({
    String? friendId,
    String? conversationId,
    int? cachedAt,
  }) => ConversationEntry(
    friendId: friendId ?? this.friendId,
    conversationId: conversationId ?? this.conversationId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ConversationEntry copyWithCompanion(ConversationsCompanion data) {
    return ConversationEntry(
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationEntry(')
          ..write('friendId: $friendId, ')
          ..write('conversationId: $conversationId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(friendId, conversationId, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationEntry &&
          other.friendId == this.friendId &&
          other.conversationId == this.conversationId &&
          other.cachedAt == this.cachedAt);
}

class ConversationsCompanion extends UpdateCompanion<ConversationEntry> {
  final Value<String> friendId;
  final Value<String> conversationId;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.friendId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String friendId,
    required String conversationId,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : friendId = Value(friendId),
       conversationId = Value(conversationId),
       cachedAt = Value(cachedAt);
  static Insertable<ConversationEntry> custom({
    Expression<String>? friendId,
    Expression<String>? conversationId,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (friendId != null) 'friend_id': friendId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? friendId,
    Value<String>? conversationId,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      friendId: friendId ?? this.friendId,
      conversationId: conversationId ?? this.conversationId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('friendId: $friendId, ')
          ..write('conversationId: $conversationId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatListCacheTable extends ChatListCache
    with TableInfo<$ChatListCacheTable, ChatListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatListCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherUserIdMeta = const VerificationMeta(
    'otherUserId',
  );
  @override
  late final GeneratedColumn<String> otherUserId = GeneratedColumn<String>(
    'other_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastMessageJsonMeta = const VerificationMeta(
    'lastMessageJson',
  );
  @override
  late final GeneratedColumn<String> lastMessageJson = GeneratedColumn<String>(
    'last_message_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversationId,
    otherUserId,
    unreadCount,
    lastMessageJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_list_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatListEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
        _otherUserIdMeta,
        otherUserId.isAcceptableOrUnknown(
          data['other_user_id']!,
          _otherUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_otherUserIdMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('last_message_json')) {
      context.handle(
        _lastMessageJsonMeta,
        lastMessageJson.isAcceptableOrUnknown(
          data['last_message_json']!,
          _lastMessageJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  ChatListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatListEntry(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      otherUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_id'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      lastMessageJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChatListCacheTable createAlias(String alias) {
    return $ChatListCacheTable(attachedDatabase, alias);
  }
}

class ChatListEntry extends DataClass implements Insertable<ChatListEntry> {
  final String conversationId;
  final String otherUserId;
  final int unreadCount;
  final String? lastMessageJson;
  final int updatedAt;
  const ChatListEntry({
    required this.conversationId,
    required this.otherUserId,
    required this.unreadCount,
    this.lastMessageJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['other_user_id'] = Variable<String>(otherUserId);
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || lastMessageJson != null) {
      map['last_message_json'] = Variable<String>(lastMessageJson);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ChatListCacheCompanion toCompanion(bool nullToAbsent) {
    return ChatListCacheCompanion(
      conversationId: Value(conversationId),
      otherUserId: Value(otherUserId),
      unreadCount: Value(unreadCount),
      lastMessageJson: lastMessageJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatListEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatListEntry(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      otherUserId: serializer.fromJson<String>(json['otherUserId']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      lastMessageJson: serializer.fromJson<String?>(json['lastMessageJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'otherUserId': serializer.toJson<String>(otherUserId),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'lastMessageJson': serializer.toJson<String?>(lastMessageJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ChatListEntry copyWith({
    String? conversationId,
    String? otherUserId,
    int? unreadCount,
    Value<String?> lastMessageJson = const Value.absent(),
    int? updatedAt,
  }) => ChatListEntry(
    conversationId: conversationId ?? this.conversationId,
    otherUserId: otherUserId ?? this.otherUserId,
    unreadCount: unreadCount ?? this.unreadCount,
    lastMessageJson: lastMessageJson.present
        ? lastMessageJson.value
        : this.lastMessageJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChatListEntry copyWithCompanion(ChatListCacheCompanion data) {
    return ChatListEntry(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      otherUserId: data.otherUserId.present
          ? data.otherUserId.value
          : this.otherUserId,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      lastMessageJson: data.lastMessageJson.present
          ? data.lastMessageJson.value
          : this.lastMessageJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatListEntry(')
          ..write('conversationId: $conversationId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastMessageJson: $lastMessageJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conversationId,
    otherUserId,
    unreadCount,
    lastMessageJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatListEntry &&
          other.conversationId == this.conversationId &&
          other.otherUserId == this.otherUserId &&
          other.unreadCount == this.unreadCount &&
          other.lastMessageJson == this.lastMessageJson &&
          other.updatedAt == this.updatedAt);
}

class ChatListCacheCompanion extends UpdateCompanion<ChatListEntry> {
  final Value<String> conversationId;
  final Value<String> otherUserId;
  final Value<int> unreadCount;
  final Value<String?> lastMessageJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ChatListCacheCompanion({
    this.conversationId = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastMessageJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatListCacheCompanion.insert({
    required String conversationId,
    required String otherUserId,
    this.unreadCount = const Value.absent(),
    this.lastMessageJson = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       otherUserId = Value(otherUserId),
       updatedAt = Value(updatedAt);
  static Insertable<ChatListEntry> custom({
    Expression<String>? conversationId,
    Expression<String>? otherUserId,
    Expression<int>? unreadCount,
    Expression<String>? lastMessageJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (lastMessageJson != null) 'last_message_json': lastMessageJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatListCacheCompanion copyWith({
    Value<String>? conversationId,
    Value<String>? otherUserId,
    Value<int>? unreadCount,
    Value<String?>? lastMessageJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChatListCacheCompanion(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageJson: lastMessageJson ?? this.lastMessageJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<String>(otherUserId.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (lastMessageJson.present) {
      map['last_message_json'] = Variable<String>(lastMessageJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatListCacheCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastMessageJson: $lastMessageJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MomentsTable extends Moments with TableInfo<$MomentsTable, MomentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MomentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image'),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _momentGroupIdMeta = const VerificationMeta(
    'momentGroupId',
  );
  @override
  late final GeneratedColumn<String> momentGroupId = GeneratedColumn<String>(
    'moment_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localMediaPathMeta = const VerificationMeta(
    'localMediaPath',
  );
  @override
  late final GeneratedColumn<String> localMediaPath = GeneratedColumn<String>(
    'local_media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localThumbnailPathMeta =
      const VerificationMeta('localThumbnailPath');
  @override
  late final GeneratedColumn<String> localThumbnailPath =
      GeneratedColumn<String>(
        'local_thumbnail_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    location,
    latitude,
    longitude,
    imageUrl,
    mediaPath,
    caption,
    mediaType,
    duration,
    thumbnailPath,
    createdAt,
    timestamp,
    userId,
    description,
    momentGroupId,
    isPrivate,
    localMediaPath,
    localThumbnailPath,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moments';
  @override
  VerificationContext validateIntegrity(
    Insertable<MomentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('moment_group_id')) {
      context.handle(
        _momentGroupIdMeta,
        momentGroupId.isAcceptableOrUnknown(
          data['moment_group_id']!,
          _momentGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('local_media_path')) {
      context.handle(
        _localMediaPathMeta,
        localMediaPath.isAcceptableOrUnknown(
          data['local_media_path']!,
          _localMediaPathMeta,
        ),
      );
    }
    if (data.containsKey('local_thumbnail_path')) {
      context.handle(
        _localThumbnailPathMeta,
        localThumbnailPath.isAcceptableOrUnknown(
          data['local_thumbnail_path']!,
          _localThumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MomentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MomentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      ),
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      momentGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moment_group_id'],
      ),
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      localMediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_media_path'],
      ),
      localThumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_thumbnail_path'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MomentsTable createAlias(String alias) {
    return $MomentsTable(attachedDatabase, alias);
  }
}

class MomentEntry extends DataClass implements Insertable<MomentEntry> {
  final String id;
  final String title;
  final String location;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? mediaPath;
  final String? caption;
  final String mediaType;
  final int? duration;
  final String? thumbnailPath;
  final int createdAt;
  final int timestamp;
  final String? userId;
  final String? description;
  final String? momentGroupId;
  final bool isPrivate;
  final String? localMediaPath;
  final String? localThumbnailPath;
  final int syncedAt;
  const MomentEntry({
    required this.id,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.mediaPath,
    this.caption,
    required this.mediaType,
    this.duration,
    this.thumbnailPath,
    required this.createdAt,
    required this.timestamp,
    this.userId,
    this.description,
    this.momentGroupId,
    required this.isPrivate,
    this.localMediaPath,
    this.localThumbnailPath,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['location'] = Variable<String>(location);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || momentGroupId != null) {
      map['moment_group_id'] = Variable<String>(momentGroupId);
    }
    map['is_private'] = Variable<bool>(isPrivate);
    if (!nullToAbsent || localMediaPath != null) {
      map['local_media_path'] = Variable<String>(localMediaPath);
    }
    if (!nullToAbsent || localThumbnailPath != null) {
      map['local_thumbnail_path'] = Variable<String>(localThumbnailPath);
    }
    map['synced_at'] = Variable<int>(syncedAt);
    return map;
  }

  MomentsCompanion toCompanion(bool nullToAbsent) {
    return MomentsCompanion(
      id: Value(id),
      title: Value(title),
      location: Value(location),
      latitude: Value(latitude),
      longitude: Value(longitude),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      mediaType: Value(mediaType),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      createdAt: Value(createdAt),
      timestamp: Value(timestamp),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      momentGroupId: momentGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(momentGroupId),
      isPrivate: Value(isPrivate),
      localMediaPath: localMediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localMediaPath),
      localThumbnailPath: localThumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localThumbnailPath),
      syncedAt: Value(syncedAt),
    );
  }

  factory MomentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MomentEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      location: serializer.fromJson<String>(json['location']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      caption: serializer.fromJson<String?>(json['caption']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      duration: serializer.fromJson<int?>(json['duration']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      userId: serializer.fromJson<String?>(json['userId']),
      description: serializer.fromJson<String?>(json['description']),
      momentGroupId: serializer.fromJson<String?>(json['momentGroupId']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      localMediaPath: serializer.fromJson<String?>(json['localMediaPath']),
      localThumbnailPath: serializer.fromJson<String?>(
        json['localThumbnailPath'],
      ),
      syncedAt: serializer.fromJson<int>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'location': serializer.toJson<String>(location),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'caption': serializer.toJson<String?>(caption),
      'mediaType': serializer.toJson<String>(mediaType),
      'duration': serializer.toJson<int?>(duration),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'timestamp': serializer.toJson<int>(timestamp),
      'userId': serializer.toJson<String?>(userId),
      'description': serializer.toJson<String?>(description),
      'momentGroupId': serializer.toJson<String?>(momentGroupId),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'localMediaPath': serializer.toJson<String?>(localMediaPath),
      'localThumbnailPath': serializer.toJson<String?>(localThumbnailPath),
      'syncedAt': serializer.toJson<int>(syncedAt),
    };
  }

  MomentEntry copyWith({
    String? id,
    String? title,
    String? location,
    double? latitude,
    double? longitude,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> mediaPath = const Value.absent(),
    Value<String?> caption = const Value.absent(),
    String? mediaType,
    Value<int?> duration = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    int? createdAt,
    int? timestamp,
    Value<String?> userId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> momentGroupId = const Value.absent(),
    bool? isPrivate,
    Value<String?> localMediaPath = const Value.absent(),
    Value<String?> localThumbnailPath = const Value.absent(),
    int? syncedAt,
  }) => MomentEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    location: location ?? this.location,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
    caption: caption.present ? caption.value : this.caption,
    mediaType: mediaType ?? this.mediaType,
    duration: duration.present ? duration.value : this.duration,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    createdAt: createdAt ?? this.createdAt,
    timestamp: timestamp ?? this.timestamp,
    userId: userId.present ? userId.value : this.userId,
    description: description.present ? description.value : this.description,
    momentGroupId: momentGroupId.present
        ? momentGroupId.value
        : this.momentGroupId,
    isPrivate: isPrivate ?? this.isPrivate,
    localMediaPath: localMediaPath.present
        ? localMediaPath.value
        : this.localMediaPath,
    localThumbnailPath: localThumbnailPath.present
        ? localThumbnailPath.value
        : this.localThumbnailPath,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MomentEntry copyWithCompanion(MomentsCompanion data) {
    return MomentEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      caption: data.caption.present ? data.caption.value : this.caption,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      userId: data.userId.present ? data.userId.value : this.userId,
      description: data.description.present
          ? data.description.value
          : this.description,
      momentGroupId: data.momentGroupId.present
          ? data.momentGroupId.value
          : this.momentGroupId,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      localMediaPath: data.localMediaPath.present
          ? data.localMediaPath.value
          : this.localMediaPath,
      localThumbnailPath: data.localThumbnailPath.present
          ? data.localThumbnailPath.value
          : this.localThumbnailPath,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MomentEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('caption: $caption, ')
          ..write('mediaType: $mediaType, ')
          ..write('duration: $duration, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('description: $description, ')
          ..write('momentGroupId: $momentGroupId, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('localThumbnailPath: $localThumbnailPath, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    location,
    latitude,
    longitude,
    imageUrl,
    mediaPath,
    caption,
    mediaType,
    duration,
    thumbnailPath,
    createdAt,
    timestamp,
    userId,
    description,
    momentGroupId,
    isPrivate,
    localMediaPath,
    localThumbnailPath,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MomentEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.imageUrl == this.imageUrl &&
          other.mediaPath == this.mediaPath &&
          other.caption == this.caption &&
          other.mediaType == this.mediaType &&
          other.duration == this.duration &&
          other.thumbnailPath == this.thumbnailPath &&
          other.createdAt == this.createdAt &&
          other.timestamp == this.timestamp &&
          other.userId == this.userId &&
          other.description == this.description &&
          other.momentGroupId == this.momentGroupId &&
          other.isPrivate == this.isPrivate &&
          other.localMediaPath == this.localMediaPath &&
          other.localThumbnailPath == this.localThumbnailPath &&
          other.syncedAt == this.syncedAt);
}

class MomentsCompanion extends UpdateCompanion<MomentEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> location;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> imageUrl;
  final Value<String?> mediaPath;
  final Value<String?> caption;
  final Value<String> mediaType;
  final Value<int?> duration;
  final Value<String?> thumbnailPath;
  final Value<int> createdAt;
  final Value<int> timestamp;
  final Value<String?> userId;
  final Value<String?> description;
  final Value<String?> momentGroupId;
  final Value<bool> isPrivate;
  final Value<String?> localMediaPath;
  final Value<String?> localThumbnailPath;
  final Value<int> syncedAt;
  final Value<int> rowid;
  const MomentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.caption = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.userId = const Value.absent(),
    this.description = const Value.absent(),
    this.momentGroupId = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    this.localThumbnailPath = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MomentsCompanion.insert({
    required String id,
    required String title,
    required String location,
    required double latitude,
    required double longitude,
    this.imageUrl = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.caption = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    required int createdAt,
    required int timestamp,
    this.userId = const Value.absent(),
    this.description = const Value.absent(),
    this.momentGroupId = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    this.localThumbnailPath = const Value.absent(),
    required int syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       location = Value(location),
       latitude = Value(latitude),
       longitude = Value(longitude),
       createdAt = Value(createdAt),
       timestamp = Value(timestamp),
       syncedAt = Value(syncedAt);
  static Insertable<MomentEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? location,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? imageUrl,
    Expression<String>? mediaPath,
    Expression<String>? caption,
    Expression<String>? mediaType,
    Expression<int>? duration,
    Expression<String>? thumbnailPath,
    Expression<int>? createdAt,
    Expression<int>? timestamp,
    Expression<String>? userId,
    Expression<String>? description,
    Expression<String>? momentGroupId,
    Expression<bool>? isPrivate,
    Expression<String>? localMediaPath,
    Expression<String>? localThumbnailPath,
    Expression<int>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (imageUrl != null) 'image_url': imageUrl,
      if (mediaPath != null) 'media_path': mediaPath,
      if (caption != null) 'caption': caption,
      if (mediaType != null) 'media_type': mediaType,
      if (duration != null) 'duration': duration,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (createdAt != null) 'created_at': createdAt,
      if (timestamp != null) 'timestamp': timestamp,
      if (userId != null) 'user_id': userId,
      if (description != null) 'description': description,
      if (momentGroupId != null) 'moment_group_id': momentGroupId,
      if (isPrivate != null) 'is_private': isPrivate,
      if (localMediaPath != null) 'local_media_path': localMediaPath,
      if (localThumbnailPath != null)
        'local_thumbnail_path': localThumbnailPath,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MomentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? location,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? imageUrl,
    Value<String?>? mediaPath,
    Value<String?>? caption,
    Value<String>? mediaType,
    Value<int?>? duration,
    Value<String?>? thumbnailPath,
    Value<int>? createdAt,
    Value<int>? timestamp,
    Value<String?>? userId,
    Value<String?>? description,
    Value<String?>? momentGroupId,
    Value<bool>? isPrivate,
    Value<String?>? localMediaPath,
    Value<String?>? localThumbnailPath,
    Value<int>? syncedAt,
    Value<int>? rowid,
  }) {
    return MomentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaPath: mediaPath ?? this.mediaPath,
      caption: caption ?? this.caption,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      momentGroupId: momentGroupId ?? this.momentGroupId,
      isPrivate: isPrivate ?? this.isPrivate,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (momentGroupId.present) {
      map['moment_group_id'] = Variable<String>(momentGroupId.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (localMediaPath.present) {
      map['local_media_path'] = Variable<String>(localMediaPath.value);
    }
    if (localThumbnailPath.present) {
      map['local_thumbnail_path'] = Variable<String>(localThumbnailPath.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MomentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('caption: $caption, ')
          ..write('mediaType: $mediaType, ')
          ..write('duration: $duration, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('timestamp: $timestamp, ')
          ..write('userId: $userId, ')
          ..write('description: $description, ')
          ..write('momentGroupId: $momentGroupId, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('localThumbnailPath: $localThumbnailPath, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCacheTable extends MediaCache
    with TableInfo<$MediaCacheTable, MediaCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedMeta = const VerificationMeta(
    'lastAccessed',
  );
  @override
  late final GeneratedColumn<int> lastAccessed = GeneratedColumn<int>(
    'last_accessed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    remotePath,
    localPath,
    fileSize,
    cachedAt,
    lastAccessed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
        _lastAccessedMeta,
        lastAccessed.isAcceptableOrUnknown(
          data['last_accessed']!,
          _lastAccessedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remotePath};
  @override
  MediaCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCacheEntry(
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_accessed'],
      )!,
    );
  }

  @override
  $MediaCacheTable createAlias(String alias) {
    return $MediaCacheTable(attachedDatabase, alias);
  }
}

class MediaCacheEntry extends DataClass implements Insertable<MediaCacheEntry> {
  final String remotePath;
  final String localPath;
  final int? fileSize;
  final int cachedAt;
  final int lastAccessed;
  const MediaCacheEntry({
    required this.remotePath,
    required this.localPath,
    this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_path'] = Variable<String>(remotePath);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['cached_at'] = Variable<int>(cachedAt);
    map['last_accessed'] = Variable<int>(lastAccessed);
    return map;
  }

  MediaCacheCompanion toCompanion(bool nullToAbsent) {
    return MediaCacheCompanion(
      remotePath: Value(remotePath),
      localPath: Value(localPath),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      cachedAt: Value(cachedAt),
      lastAccessed: Value(lastAccessed),
    );
  }

  factory MediaCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCacheEntry(
      remotePath: serializer.fromJson<String>(json['remotePath']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      lastAccessed: serializer.fromJson<int>(json['lastAccessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remotePath': serializer.toJson<String>(remotePath),
      'localPath': serializer.toJson<String>(localPath),
      'fileSize': serializer.toJson<int?>(fileSize),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'lastAccessed': serializer.toJson<int>(lastAccessed),
    };
  }

  MediaCacheEntry copyWith({
    String? remotePath,
    String? localPath,
    Value<int?> fileSize = const Value.absent(),
    int? cachedAt,
    int? lastAccessed,
  }) => MediaCacheEntry(
    remotePath: remotePath ?? this.remotePath,
    localPath: localPath ?? this.localPath,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessed: lastAccessed ?? this.lastAccessed,
  );
  MediaCacheEntry copyWithCompanion(MediaCacheCompanion data) {
    return MediaCacheEntry(
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheEntry(')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(remotePath, localPath, fileSize, cachedAt, lastAccessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCacheEntry &&
          other.remotePath == this.remotePath &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessed == this.lastAccessed);
}

class MediaCacheCompanion extends UpdateCompanion<MediaCacheEntry> {
  final Value<String> remotePath;
  final Value<String> localPath;
  final Value<int?> fileSize;
  final Value<int> cachedAt;
  final Value<int> lastAccessed;
  final Value<int> rowid;
  const MediaCacheCompanion({
    this.remotePath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCacheCompanion.insert({
    required String remotePath,
    required String localPath,
    this.fileSize = const Value.absent(),
    required int cachedAt,
    required int lastAccessed,
    this.rowid = const Value.absent(),
  }) : remotePath = Value(remotePath),
       localPath = Value(localPath),
       cachedAt = Value(cachedAt),
       lastAccessed = Value(lastAccessed);
  static Insertable<MediaCacheEntry> custom({
    Expression<String>? remotePath,
    Expression<String>? localPath,
    Expression<int>? fileSize,
    Expression<int>? cachedAt,
    Expression<int>? lastAccessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remotePath != null) 'remote_path': remotePath,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCacheCompanion copyWith({
    Value<String>? remotePath,
    Value<String>? localPath,
    Value<int?>? fileSize,
    Value<int>? cachedAt,
    Value<int>? lastAccessed,
    Value<int>? rowid,
  }) {
    return MediaCacheCompanion(
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<int>(lastAccessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheCompanion(')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    displayName,
    avatarUrl,
    bio,
    inviteCode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileEntry extends DataClass implements Insertable<ProfileEntry> {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? inviteCode;
  final int? createdAt;
  final int? updatedAt;
  const ProfileEntry({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.inviteCode,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ProfileEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileEntry(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String?>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      bio: serializer.fromJson<String?>(json['bio']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String?>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'bio': serializer.toJson<String?>(bio),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  ProfileEntry copyWith({
    String? id,
    Value<String?> username = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> inviteCode = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => ProfileEntry(
    id: id ?? this.id,
    username: username.present ? username.value : this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    bio: bio.present ? bio.value : this.bio,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ProfileEntry copyWithCompanion(ProfilesCompanion data) {
    return ProfileEntry(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      bio: data.bio.present ? data.bio.value : this.bio,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileEntry(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    displayName,
    avatarUrl,
    bio,
    inviteCode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileEntry &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.bio == this.bio &&
          other.inviteCode == this.inviteCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileEntry> {
  final Value<String> id;
  final Value<String?> username;
  final Value<String?> displayName;
  final Value<String?> avatarUrl;
  final Value<String?> bio;
  final Value<String?> inviteCode;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ProfileEntry> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<String>? bio,
    Expression<String>? inviteCode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? username,
    Value<String?>? displayName,
    Value<String?>? avatarUrl,
    Value<String?>? bio,
    Value<String?>? inviteCode,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FriendshipsTable extends Friendships
    with TableInfo<$FriendshipsTable, FriendshipEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userId1Meta = const VerificationMeta(
    'userId1',
  );
  @override
  late final GeneratedColumn<String> userId1 = GeneratedColumn<String>(
    'user_id1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userId2Meta = const VerificationMeta(
    'userId2',
  );
  @override
  late final GeneratedColumn<String> userId2 = GeneratedColumn<String>(
    'user_id2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId1,
    userId2,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friendships';
  @override
  VerificationContext validateIntegrity(
    Insertable<FriendshipEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id1')) {
      context.handle(
        _userId1Meta,
        userId1.isAcceptableOrUnknown(data['user_id1']!, _userId1Meta),
      );
    } else if (isInserting) {
      context.missing(_userId1Meta);
    }
    if (data.containsKey('user_id2')) {
      context.handle(
        _userId2Meta,
        userId2.isAcceptableOrUnknown(data['user_id2']!, _userId2Meta),
      );
    } else if (isInserting) {
      context.missing(_userId2Meta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FriendshipEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FriendshipEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id1'],
      )!,
      userId2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id2'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $FriendshipsTable createAlias(String alias) {
    return $FriendshipsTable(attachedDatabase, alias);
  }
}

class FriendshipEntry extends DataClass implements Insertable<FriendshipEntry> {
  final String id;
  final String userId1;
  final String userId2;
  final String status;
  final int? createdAt;
  final int? updatedAt;
  const FriendshipEntry({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id1'] = Variable<String>(userId1);
    map['user_id2'] = Variable<String>(userId2);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  FriendshipsCompanion toCompanion(bool nullToAbsent) {
    return FriendshipsCompanion(
      id: Value(id),
      userId1: Value(userId1),
      userId2: Value(userId2),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory FriendshipEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FriendshipEntry(
      id: serializer.fromJson<String>(json['id']),
      userId1: serializer.fromJson<String>(json['userId1']),
      userId2: serializer.fromJson<String>(json['userId2']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId1': serializer.toJson<String>(userId1),
      'userId2': serializer.toJson<String>(userId2),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  FriendshipEntry copyWith({
    String? id,
    String? userId1,
    String? userId2,
    String? status,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => FriendshipEntry(
    id: id ?? this.id,
    userId1: userId1 ?? this.userId1,
    userId2: userId2 ?? this.userId2,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  FriendshipEntry copyWithCompanion(FriendshipsCompanion data) {
    return FriendshipEntry(
      id: data.id.present ? data.id.value : this.id,
      userId1: data.userId1.present ? data.userId1.value : this.userId1,
      userId2: data.userId2.present ? data.userId2.value : this.userId2,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FriendshipEntry(')
          ..write('id: $id, ')
          ..write('userId1: $userId1, ')
          ..write('userId2: $userId2, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId1, userId2, status, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendshipEntry &&
          other.id == this.id &&
          other.userId1 == this.userId1 &&
          other.userId2 == this.userId2 &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FriendshipsCompanion extends UpdateCompanion<FriendshipEntry> {
  final Value<String> id;
  final Value<String> userId1;
  final Value<String> userId2;
  final Value<String> status;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const FriendshipsCompanion({
    this.id = const Value.absent(),
    this.userId1 = const Value.absent(),
    this.userId2 = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FriendshipsCompanion.insert({
    required String id,
    required String userId1,
    required String userId2,
    required String status,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId1 = Value(userId1),
       userId2 = Value(userId2),
       status = Value(status);
  static Insertable<FriendshipEntry> custom({
    Expression<String>? id,
    Expression<String>? userId1,
    Expression<String>? userId2,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId1 != null) 'user_id1': userId1,
      if (userId2 != null) 'user_id2': userId2,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FriendshipsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId1,
    Value<String>? userId2,
    Value<String>? status,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int>? rowid,
  }) {
    return FriendshipsCompanion(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId1.present) {
      map['user_id1'] = Variable<String>(userId1.value);
    }
    if (userId2.present) {
      map['user_id2'] = Variable<String>(userId2.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendshipsCompanion(')
          ..write('id: $id, ')
          ..write('userId1: $userId1, ')
          ..write('userId2: $userId2, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActionsTable extends PendingActions
    with TableInfo<$PendingActionsTable, PendingActionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingActionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingActionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingActionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $PendingActionsTable createAlias(String alias) {
    return $PendingActionsTable(attachedDatabase, alias);
  }
}

class PendingActionEntry extends DataClass
    implements Insertable<PendingActionEntry> {
  final String id;
  final String actionType;
  final String entityType;
  final String entityId;
  final String? payload;
  final String createdAt;
  final int retryCount;
  final String? lastError;
  final String priority;
  const PendingActionEntry({
    required this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.payload,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['action_type'] = Variable<String>(actionType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['priority'] = Variable<String>(priority);
    return map;
  }

  PendingActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingActionsCompanion(
      id: Value(id),
      actionType: Value(actionType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      priority: Value(priority),
    );
  }

  factory PendingActionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingActionEntry(
      id: serializer.fromJson<String>(json['id']),
      actionType: serializer.fromJson<String>(json['actionType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      priority: serializer.fromJson<String>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionType': serializer.toJson<String>(actionType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<String>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'priority': serializer.toJson<String>(priority),
    };
  }

  PendingActionEntry copyWith({
    String? id,
    String? actionType,
    String? entityType,
    String? entityId,
    Value<String?> payload = const Value.absent(),
    String? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    String? priority,
  }) => PendingActionEntry(
    id: id ?? this.id,
    actionType: actionType ?? this.actionType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payload: payload.present ? payload.value : this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    priority: priority ?? this.priority,
  );
  PendingActionEntry copyWithCompanion(PendingActionsCompanion data) {
    return PendingActionEntry(
      id: data.id.present ? data.id.value : this.id,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionEntry(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionType,
    entityType,
    entityId,
    payload,
    createdAt,
    retryCount,
    lastError,
    priority,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingActionEntry &&
          other.id == this.id &&
          other.actionType == this.actionType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.priority == this.priority);
}

class PendingActionsCompanion extends UpdateCompanion<PendingActionEntry> {
  final Value<String> id;
  final Value<String> actionType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> payload;
  final Value<String> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<String> priority;
  final Value<int> rowid;
  const PendingActionsCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingActionsCompanion.insert({
    required String id,
    required String actionType,
    required String entityType,
    required String entityId,
    this.payload = const Value.absent(),
    required String createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionType = Value(actionType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       createdAt = Value(createdAt);
  static Insertable<PendingActionEntry> custom({
    Expression<String>? id,
    Expression<String>? actionType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<String>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<String>? priority,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionType != null) 'action_type': actionType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (priority != null) 'priority': priority,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingActionsCompanion copyWith({
    Value<String>? id,
    Value<String>? actionType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? payload,
    Value<String>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<String>? priority,
    Value<int>? rowid,
  }) {
    return PendingActionsCompanion(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      priority: priority ?? this.priority,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionsCompanion(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('priority: $priority, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ChatListCacheTable chatListCache = $ChatListCacheTable(this);
  late final $MomentsTable moments = $MomentsTable(this);
  late final $MediaCacheTable mediaCache = $MediaCacheTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $FriendshipsTable friendships = $FriendshipsTable(this);
  late final $PendingActionsTable pendingActions = $PendingActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    conversations,
    chatListCache,
    moments,
    mediaCache,
    profiles,
    friendships,
    pendingActions,
  ];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String conversationId,
      required String senderId,
      required String content,
      Value<String> messageType,
      Value<String?> mediaUrl,
      Value<String?> metadata,
      required int createdAt,
      Value<bool> isRead,
      Value<bool> isDeleted,
      Value<String?> replyToMessageId,
      Value<String?> replyToContent,
      Value<String?> replySenderName,
      Value<String?> reactions,
      Value<String?> deletedFor,
      Value<bool> isEdited,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> content,
      Value<String> messageType,
      Value<String?> mediaUrl,
      Value<String?> metadata,
      Value<int> createdAt,
      Value<bool> isRead,
      Value<bool> isDeleted,
      Value<String?> replyToMessageId,
      Value<String?> replyToContent,
      Value<String?> replySenderName,
      Value<String?> reactions,
      Value<String?> deletedFor,
      Value<bool> isEdited,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToContent => $composableBuilder(
    column: $table.replyToContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replySenderName => $composableBuilder(
    column: $table.replySenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactions => $composableBuilder(
    column: $table.reactions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedFor => $composableBuilder(
    column: $table.deletedFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToContent => $composableBuilder(
    column: $table.replyToContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replySenderName => $composableBuilder(
    column: $table.replySenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactions => $composableBuilder(
    column: $table.reactions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedFor => $composableBuilder(
    column: $table.deletedFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToContent => $composableBuilder(
    column: $table.replyToContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replySenderName => $composableBuilder(
    column: $table.replySenderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reactions =>
      $composableBuilder(column: $table.reactions, builder: (column) => column);

  GeneratedColumn<String> get deletedFor => $composableBuilder(
    column: $table.deletedFor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageEntry,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageEntry,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageEntry>,
          ),
          MessageEntry,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<String?> replyToContent = const Value.absent(),
                Value<String?> replySenderName = const Value.absent(),
                Value<String?> reactions = const Value.absent(),
                Value<String?> deletedFor = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                messageType: messageType,
                mediaUrl: mediaUrl,
                metadata: metadata,
                createdAt: createdAt,
                isRead: isRead,
                isDeleted: isDeleted,
                replyToMessageId: replyToMessageId,
                replyToContent: replyToContent,
                replySenderName: replySenderName,
                reactions: reactions,
                deletedFor: deletedFor,
                isEdited: isEdited,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String senderId,
                required String content,
                Value<String> messageType = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required int createdAt,
                Value<bool> isRead = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> replyToMessageId = const Value.absent(),
                Value<String?> replyToContent = const Value.absent(),
                Value<String?> replySenderName = const Value.absent(),
                Value<String?> reactions = const Value.absent(),
                Value<String?> deletedFor = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                messageType: messageType,
                mediaUrl: mediaUrl,
                metadata: metadata,
                createdAt: createdAt,
                isRead: isRead,
                isDeleted: isDeleted,
                replyToMessageId: replyToMessageId,
                replyToContent: replyToContent,
                replySenderName: replySenderName,
                reactions: reactions,
                deletedFor: deletedFor,
                isEdited: isEdited,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageEntry,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (
        MessageEntry,
        BaseReferences<_$AppDatabase, $MessagesTable, MessageEntry>,
      ),
      MessageEntry,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String friendId,
      required String conversationId,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> friendId,
      Value<String> conversationId,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationEntry,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            ConversationEntry,
            BaseReferences<
              _$AppDatabase,
              $ConversationsTable,
              ConversationEntry
            >,
          ),
          ConversationEntry,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> friendId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                friendId: friendId,
                conversationId: conversationId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String friendId,
                required String conversationId,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                friendId: friendId,
                conversationId: conversationId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationEntry,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        ConversationEntry,
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationEntry>,
      ),
      ConversationEntry,
      PrefetchHooks Function()
    >;
typedef $$ChatListCacheTableCreateCompanionBuilder =
    ChatListCacheCompanion Function({
      required String conversationId,
      required String otherUserId,
      Value<int> unreadCount,
      Value<String?> lastMessageJson,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ChatListCacheTableUpdateCompanionBuilder =
    ChatListCacheCompanion Function({
      Value<String> conversationId,
      Value<String> otherUserId,
      Value<int> unreadCount,
      Value<String?> lastMessageJson,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ChatListCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ChatListCacheTable> {
  $$ChatListCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageJson => $composableBuilder(
    column: $table.lastMessageJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatListCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatListCacheTable> {
  $$ChatListCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageJson => $composableBuilder(
    column: $table.lastMessageJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatListCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatListCacheTable> {
  $$ChatListCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageJson => $composableBuilder(
    column: $table.lastMessageJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChatListCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatListCacheTable,
          ChatListEntry,
          $$ChatListCacheTableFilterComposer,
          $$ChatListCacheTableOrderingComposer,
          $$ChatListCacheTableAnnotationComposer,
          $$ChatListCacheTableCreateCompanionBuilder,
          $$ChatListCacheTableUpdateCompanionBuilder,
          (
            ChatListEntry,
            BaseReferences<_$AppDatabase, $ChatListCacheTable, ChatListEntry>,
          ),
          ChatListEntry,
          PrefetchHooks Function()
        > {
  $$ChatListCacheTableTableManager(_$AppDatabase db, $ChatListCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatListCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatListCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatListCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<String> otherUserId = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<String?> lastMessageJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatListCacheCompanion(
                conversationId: conversationId,
                otherUserId: otherUserId,
                unreadCount: unreadCount,
                lastMessageJson: lastMessageJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                required String otherUserId,
                Value<int> unreadCount = const Value.absent(),
                Value<String?> lastMessageJson = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatListCacheCompanion.insert(
                conversationId: conversationId,
                otherUserId: otherUserId,
                unreadCount: unreadCount,
                lastMessageJson: lastMessageJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatListCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatListCacheTable,
      ChatListEntry,
      $$ChatListCacheTableFilterComposer,
      $$ChatListCacheTableOrderingComposer,
      $$ChatListCacheTableAnnotationComposer,
      $$ChatListCacheTableCreateCompanionBuilder,
      $$ChatListCacheTableUpdateCompanionBuilder,
      (
        ChatListEntry,
        BaseReferences<_$AppDatabase, $ChatListCacheTable, ChatListEntry>,
      ),
      ChatListEntry,
      PrefetchHooks Function()
    >;
typedef $$MomentsTableCreateCompanionBuilder =
    MomentsCompanion Function({
      required String id,
      required String title,
      required String location,
      required double latitude,
      required double longitude,
      Value<String?> imageUrl,
      Value<String?> mediaPath,
      Value<String?> caption,
      Value<String> mediaType,
      Value<int?> duration,
      Value<String?> thumbnailPath,
      required int createdAt,
      required int timestamp,
      Value<String?> userId,
      Value<String?> description,
      Value<String?> momentGroupId,
      Value<bool> isPrivate,
      Value<String?> localMediaPath,
      Value<String?> localThumbnailPath,
      required int syncedAt,
      Value<int> rowid,
    });
typedef $$MomentsTableUpdateCompanionBuilder =
    MomentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> location,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> imageUrl,
      Value<String?> mediaPath,
      Value<String?> caption,
      Value<String> mediaType,
      Value<int?> duration,
      Value<String?> thumbnailPath,
      Value<int> createdAt,
      Value<int> timestamp,
      Value<String?> userId,
      Value<String?> description,
      Value<String?> momentGroupId,
      Value<bool> isPrivate,
      Value<String?> localMediaPath,
      Value<String?> localThumbnailPath,
      Value<int> syncedAt,
      Value<int> rowid,
    });

class $$MomentsTableFilterComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get momentGroupId => $composableBuilder(
    column: $table.momentGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MomentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get momentGroupId => $composableBuilder(
    column: $table.momentGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MomentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get momentGroupId => $composableBuilder(
    column: $table.momentGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MomentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MomentsTable,
          MomentEntry,
          $$MomentsTableFilterComposer,
          $$MomentsTableOrderingComposer,
          $$MomentsTableAnnotationComposer,
          $$MomentsTableCreateCompanionBuilder,
          $$MomentsTableUpdateCompanionBuilder,
          (
            MomentEntry,
            BaseReferences<_$AppDatabase, $MomentsTable, MomentEntry>,
          ),
          MomentEntry,
          PrefetchHooks Function()
        > {
  $$MomentsTableTableManager(_$AppDatabase db, $MomentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MomentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MomentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MomentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> mediaPath = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> momentGroupId = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                Value<String?> localThumbnailPath = const Value.absent(),
                Value<int> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MomentsCompanion(
                id: id,
                title: title,
                location: location,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                mediaPath: mediaPath,
                caption: caption,
                mediaType: mediaType,
                duration: duration,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                timestamp: timestamp,
                userId: userId,
                description: description,
                momentGroupId: momentGroupId,
                isPrivate: isPrivate,
                localMediaPath: localMediaPath,
                localThumbnailPath: localThumbnailPath,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String location,
                required double latitude,
                required double longitude,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> mediaPath = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                required int createdAt,
                required int timestamp,
                Value<String?> userId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> momentGroupId = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                Value<String?> localThumbnailPath = const Value.absent(),
                required int syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => MomentsCompanion.insert(
                id: id,
                title: title,
                location: location,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                mediaPath: mediaPath,
                caption: caption,
                mediaType: mediaType,
                duration: duration,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                timestamp: timestamp,
                userId: userId,
                description: description,
                momentGroupId: momentGroupId,
                isPrivate: isPrivate,
                localMediaPath: localMediaPath,
                localThumbnailPath: localThumbnailPath,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MomentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MomentsTable,
      MomentEntry,
      $$MomentsTableFilterComposer,
      $$MomentsTableOrderingComposer,
      $$MomentsTableAnnotationComposer,
      $$MomentsTableCreateCompanionBuilder,
      $$MomentsTableUpdateCompanionBuilder,
      (MomentEntry, BaseReferences<_$AppDatabase, $MomentsTable, MomentEntry>),
      MomentEntry,
      PrefetchHooks Function()
    >;
typedef $$MediaCacheTableCreateCompanionBuilder =
    MediaCacheCompanion Function({
      required String remotePath,
      required String localPath,
      Value<int?> fileSize,
      required int cachedAt,
      required int lastAccessed,
      Value<int> rowid,
    });
typedef $$MediaCacheTableUpdateCompanionBuilder =
    MediaCacheCompanion Function({
      Value<String> remotePath,
      Value<String> localPath,
      Value<int?> fileSize,
      Value<int> cachedAt,
      Value<int> lastAccessed,
      Value<int> rowid,
    });

class $$MediaCacheTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCacheTable> {
  $$MediaCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCacheTable> {
  $$MediaCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCacheTable> {
  $$MediaCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => column,
  );
}

class $$MediaCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaCacheTable,
          MediaCacheEntry,
          $$MediaCacheTableFilterComposer,
          $$MediaCacheTableOrderingComposer,
          $$MediaCacheTableAnnotationComposer,
          $$MediaCacheTableCreateCompanionBuilder,
          $$MediaCacheTableUpdateCompanionBuilder,
          (
            MediaCacheEntry,
            BaseReferences<_$AppDatabase, $MediaCacheTable, MediaCacheEntry>,
          ),
          MediaCacheEntry,
          PrefetchHooks Function()
        > {
  $$MediaCacheTableTableManager(_$AppDatabase db, $MediaCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remotePath = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> lastAccessed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCacheCompanion(
                remotePath: remotePath,
                localPath: localPath,
                fileSize: fileSize,
                cachedAt: cachedAt,
                lastAccessed: lastAccessed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remotePath,
                required String localPath,
                Value<int?> fileSize = const Value.absent(),
                required int cachedAt,
                required int lastAccessed,
                Value<int> rowid = const Value.absent(),
              }) => MediaCacheCompanion.insert(
                remotePath: remotePath,
                localPath: localPath,
                fileSize: fileSize,
                cachedAt: cachedAt,
                lastAccessed: lastAccessed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaCacheTable,
      MediaCacheEntry,
      $$MediaCacheTableFilterComposer,
      $$MediaCacheTableOrderingComposer,
      $$MediaCacheTableAnnotationComposer,
      $$MediaCacheTableCreateCompanionBuilder,
      $$MediaCacheTableUpdateCompanionBuilder,
      (
        MediaCacheEntry,
        BaseReferences<_$AppDatabase, $MediaCacheTable, MediaCacheEntry>,
      ),
      MediaCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> inviteCode,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> inviteCode,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileEntry,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileEntry,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileEntry>,
          ),
          ProfileEntry,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                bio: bio,
                inviteCode: inviteCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                bio: bio,
                inviteCode: inviteCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileEntry,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (
        ProfileEntry,
        BaseReferences<_$AppDatabase, $ProfilesTable, ProfileEntry>,
      ),
      ProfileEntry,
      PrefetchHooks Function()
    >;
typedef $$FriendshipsTableCreateCompanionBuilder =
    FriendshipsCompanion Function({
      required String id,
      required String userId1,
      required String userId2,
      required String status,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int> rowid,
    });
typedef $$FriendshipsTableUpdateCompanionBuilder =
    FriendshipsCompanion Function({
      Value<String> id,
      Value<String> userId1,
      Value<String> userId2,
      Value<String> status,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int> rowid,
    });

class $$FriendshipsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendshipsTable> {
  $$FriendshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId1 => $composableBuilder(
    column: $table.userId1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId2 => $composableBuilder(
    column: $table.userId2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendshipsTable> {
  $$FriendshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId1 => $composableBuilder(
    column: $table.userId1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId2 => $composableBuilder(
    column: $table.userId2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendshipsTable> {
  $$FriendshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId1 =>
      $composableBuilder(column: $table.userId1, builder: (column) => column);

  GeneratedColumn<String> get userId2 =>
      $composableBuilder(column: $table.userId2, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FriendshipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FriendshipsTable,
          FriendshipEntry,
          $$FriendshipsTableFilterComposer,
          $$FriendshipsTableOrderingComposer,
          $$FriendshipsTableAnnotationComposer,
          $$FriendshipsTableCreateCompanionBuilder,
          $$FriendshipsTableUpdateCompanionBuilder,
          (
            FriendshipEntry,
            BaseReferences<_$AppDatabase, $FriendshipsTable, FriendshipEntry>,
          ),
          FriendshipEntry,
          PrefetchHooks Function()
        > {
  $$FriendshipsTableTableManager(_$AppDatabase db, $FriendshipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendshipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendshipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId1 = const Value.absent(),
                Value<String> userId2 = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FriendshipsCompanion(
                id: id,
                userId1: userId1,
                userId2: userId2,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId1,
                required String userId2,
                required String status,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FriendshipsCompanion.insert(
                id: id,
                userId1: userId1,
                userId2: userId2,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FriendshipsTable,
      FriendshipEntry,
      $$FriendshipsTableFilterComposer,
      $$FriendshipsTableOrderingComposer,
      $$FriendshipsTableAnnotationComposer,
      $$FriendshipsTableCreateCompanionBuilder,
      $$FriendshipsTableUpdateCompanionBuilder,
      (
        FriendshipEntry,
        BaseReferences<_$AppDatabase, $FriendshipsTable, FriendshipEntry>,
      ),
      FriendshipEntry,
      PrefetchHooks Function()
    >;
typedef $$PendingActionsTableCreateCompanionBuilder =
    PendingActionsCompanion Function({
      required String id,
      required String actionType,
      required String entityType,
      required String entityId,
      Value<String?> payload,
      required String createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> priority,
      Value<int> rowid,
    });
typedef $$PendingActionsTableUpdateCompanionBuilder =
    PendingActionsCompanion Function({
      Value<String> id,
      Value<String> actionType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String?> payload,
      Value<String> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String> priority,
      Value<int> rowid,
    });

class $$PendingActionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$PendingActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingActionsTable,
          PendingActionEntry,
          $$PendingActionsTableFilterComposer,
          $$PendingActionsTableOrderingComposer,
          $$PendingActionsTableAnnotationComposer,
          $$PendingActionsTableCreateCompanionBuilder,
          $$PendingActionsTableUpdateCompanionBuilder,
          (
            PendingActionEntry,
            BaseReferences<
              _$AppDatabase,
              $PendingActionsTable,
              PendingActionEntry
            >,
          ),
          PendingActionEntry,
          PrefetchHooks Function()
        > {
  $$PendingActionsTableTableManager(
    _$AppDatabase db,
    $PendingActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingActionsCompanion(
                id: id,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                priority: priority,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String actionType,
                required String entityType,
                required String entityId,
                Value<String?> payload = const Value.absent(),
                required String createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingActionsCompanion.insert(
                id: id,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                priority: priority,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingActionsTable,
      PendingActionEntry,
      $$PendingActionsTableFilterComposer,
      $$PendingActionsTableOrderingComposer,
      $$PendingActionsTableAnnotationComposer,
      $$PendingActionsTableCreateCompanionBuilder,
      $$PendingActionsTableUpdateCompanionBuilder,
      (
        PendingActionEntry,
        BaseReferences<_$AppDatabase, $PendingActionsTable, PendingActionEntry>,
      ),
      PendingActionEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ChatListCacheTableTableManager get chatListCache =>
      $$ChatListCacheTableTableManager(_db, _db.chatListCache);
  $$MomentsTableTableManager get moments =>
      $$MomentsTableTableManager(_db, _db.moments);
  $$MediaCacheTableTableManager get mediaCache =>
      $$MediaCacheTableTableManager(_db, _db.mediaCache);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$FriendshipsTableTableManager get friendships =>
      $$FriendshipsTableTableManager(_db, _db.friendships);
  $$PendingActionsTableTableManager get pendingActions =>
      $$PendingActionsTableTableManager(_db, _db.pendingActions);
}

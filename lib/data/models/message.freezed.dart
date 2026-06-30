// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Message {

 String get id; String get conversationId; String get senderId; String get content;@JsonKey(unknownEnumValue: MessageType.text) MessageType get messageType; String? get mediaUrl; String? get localMediaPath;@MetadataConverter() Map<String, dynamic>? get metadata;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get createdAt;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get updatedAt;@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool get isDeleted;@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool get isRead; String? get replyToMessageId; Message? get replyToMessage;@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool get isEdited; String? get deletedFor; List<Reaction> get reactions;@JsonKey(unknownEnumValue: MessageSendStatus.sent) MessageSendStatus get sendStatus;@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool get localOnly;@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get deliveredAt;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.localMediaPath, localMediaPath) || other.localMediaPath == localMediaPath)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToMessage, replyToMessage) || other.replyToMessage == replyToMessage)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.deletedFor, deletedFor) || other.deletedFor == deletedFor)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.sendStatus, sendStatus) || other.sendStatus == sendStatus)&&(identical(other.localOnly, localOnly) || other.localOnly == localOnly)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conversationId,senderId,content,messageType,mediaUrl,localMediaPath,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt,isDeleted,isRead,replyToMessageId,replyToMessage,isEdited,deletedFor,const DeepCollectionEquality().hash(reactions),sendStatus,localOnly,deliveredAt]);

@override
String toString() {
  return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, messageType: $messageType, mediaUrl: $mediaUrl, localMediaPath: $localMediaPath, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, isRead: $isRead, replyToMessageId: $replyToMessageId, replyToMessage: $replyToMessage, isEdited: $isEdited, deletedFor: $deletedFor, reactions: $reactions, sendStatus: $sendStatus, localOnly: $localOnly, deliveredAt: $deliveredAt)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String senderId, String content,@JsonKey(unknownEnumValue: MessageType.text) MessageType messageType, String? mediaUrl, String? localMediaPath,@MetadataConverter() Map<String, dynamic>? metadata,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime updatedAt,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isDeleted,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isRead, String? replyToMessageId, Message? replyToMessage,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isEdited, String? deletedFor, List<Reaction> reactions,@JsonKey(unknownEnumValue: MessageSendStatus.sent) MessageSendStatus sendStatus,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool localOnly,@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? deliveredAt
});


$MessageCopyWith<$Res>? get replyToMessage;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = null,Object? messageType = null,Object? mediaUrl = freezed,Object? localMediaPath = freezed,Object? metadata = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? isRead = null,Object? replyToMessageId = freezed,Object? replyToMessage = freezed,Object? isEdited = null,Object? deletedFor = freezed,Object? reactions = null,Object? sendStatus = null,Object? localOnly = null,Object? deliveredAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,localMediaPath: freezed == localMediaPath ? _self.localMediaPath : localMediaPath // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as Message?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,deletedFor: freezed == deletedFor ? _self.deletedFor : deletedFor // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Reaction>,sendStatus: null == sendStatus ? _self.sendStatus : sendStatus // ignore: cast_nullable_to_non_nullable
as MessageSendStatus,localOnly: null == localOnly ? _self.localOnly : localOnly // ignore: cast_nullable_to_non_nullable
as bool,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get replyToMessage {
    if (_self.replyToMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.replyToMessage!, (value) {
    return _then(_self.copyWith(replyToMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String content, @JsonKey(unknownEnumValue: MessageType.text)  MessageType messageType,  String? mediaUrl,  String? localMediaPath, @MetadataConverter()  Map<String, dynamic>? metadata, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime updatedAt, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isDeleted, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isRead,  String? replyToMessageId,  Message? replyToMessage, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isEdited,  String? deletedFor,  List<Reaction> reactions, @JsonKey(unknownEnumValue: MessageSendStatus.sent)  MessageSendStatus sendStatus, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool localOnly, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.messageType,_that.mediaUrl,_that.localMediaPath,_that.metadata,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isRead,_that.replyToMessageId,_that.replyToMessage,_that.isEdited,_that.deletedFor,_that.reactions,_that.sendStatus,_that.localOnly,_that.deliveredAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String content, @JsonKey(unknownEnumValue: MessageType.text)  MessageType messageType,  String? mediaUrl,  String? localMediaPath, @MetadataConverter()  Map<String, dynamic>? metadata, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime updatedAt, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isDeleted, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isRead,  String? replyToMessageId,  Message? replyToMessage, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isEdited,  String? deletedFor,  List<Reaction> reactions, @JsonKey(unknownEnumValue: MessageSendStatus.sent)  MessageSendStatus sendStatus, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool localOnly, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredAt)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.messageType,_that.mediaUrl,_that.localMediaPath,_that.metadata,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isRead,_that.replyToMessageId,_that.replyToMessage,_that.isEdited,_that.deletedFor,_that.reactions,_that.sendStatus,_that.localOnly,_that.deliveredAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String senderId,  String content, @JsonKey(unknownEnumValue: MessageType.text)  MessageType messageType,  String? mediaUrl,  String? localMediaPath, @MetadataConverter()  Map<String, dynamic>? metadata, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime updatedAt, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isDeleted, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isRead,  String? replyToMessageId,  Message? replyToMessage, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isEdited,  String? deletedFor,  List<Reaction> reactions, @JsonKey(unknownEnumValue: MessageSendStatus.sent)  MessageSendStatus sendStatus, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool localOnly, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredAt)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.messageType,_that.mediaUrl,_that.localMediaPath,_that.metadata,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isRead,_that.replyToMessageId,_that.replyToMessage,_that.isEdited,_that.deletedFor,_that.reactions,_that.sendStatus,_that.localOnly,_that.deliveredAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Message implements Message {
  const _Message({required this.id, required this.conversationId, required this.senderId, required this.content, @JsonKey(unknownEnumValue: MessageType.text) required this.messageType, this.mediaUrl, this.localMediaPath, @MetadataConverter() final  Map<String, dynamic>? metadata, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.updatedAt, @JsonKey(fromJson: boolFromJson, toJson: boolToJson) this.isDeleted = false, @JsonKey(fromJson: boolFromJson, toJson: boolToJson) this.isRead = false, this.replyToMessageId, this.replyToMessage, @JsonKey(fromJson: boolFromJson, toJson: boolToJson) this.isEdited = false, this.deletedFor, final  List<Reaction> reactions = const [], @JsonKey(unknownEnumValue: MessageSendStatus.sent) this.sendStatus = MessageSendStatus.sent, @JsonKey(fromJson: boolFromJson, toJson: boolToJson) this.localOnly = false, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) this.deliveredAt}): _metadata = metadata,_reactions = reactions;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override final  String conversationId;
@override final  String senderId;
@override final  String content;
@override@JsonKey(unknownEnumValue: MessageType.text) final  MessageType messageType;
@override final  String? mediaUrl;
@override final  String? localMediaPath;
 final  Map<String, dynamic>? _metadata;
@override@MetadataConverter() Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime createdAt;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime updatedAt;
@override@JsonKey(fromJson: boolFromJson, toJson: boolToJson) final  bool isDeleted;
@override@JsonKey(fromJson: boolFromJson, toJson: boolToJson) final  bool isRead;
@override final  String? replyToMessageId;
@override final  Message? replyToMessage;
@override@JsonKey(fromJson: boolFromJson, toJson: boolToJson) final  bool isEdited;
@override final  String? deletedFor;
 final  List<Reaction> _reactions;
@override@JsonKey() List<Reaction> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

@override@JsonKey(unknownEnumValue: MessageSendStatus.sent) final  MessageSendStatus sendStatus;
@override@JsonKey(fromJson: boolFromJson, toJson: boolToJson) final  bool localOnly;
@override@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? deliveredAt;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.localMediaPath, localMediaPath) || other.localMediaPath == localMediaPath)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToMessage, replyToMessage) || other.replyToMessage == replyToMessage)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.deletedFor, deletedFor) || other.deletedFor == deletedFor)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.sendStatus, sendStatus) || other.sendStatus == sendStatus)&&(identical(other.localOnly, localOnly) || other.localOnly == localOnly)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conversationId,senderId,content,messageType,mediaUrl,localMediaPath,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt,isDeleted,isRead,replyToMessageId,replyToMessage,isEdited,deletedFor,const DeepCollectionEquality().hash(_reactions),sendStatus,localOnly,deliveredAt]);

@override
String toString() {
  return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, messageType: $messageType, mediaUrl: $mediaUrl, localMediaPath: $localMediaPath, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, isRead: $isRead, replyToMessageId: $replyToMessageId, replyToMessage: $replyToMessage, isEdited: $isEdited, deletedFor: $deletedFor, reactions: $reactions, sendStatus: $sendStatus, localOnly: $localOnly, deliveredAt: $deliveredAt)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String senderId, String content,@JsonKey(unknownEnumValue: MessageType.text) MessageType messageType, String? mediaUrl, String? localMediaPath,@MetadataConverter() Map<String, dynamic>? metadata,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime updatedAt,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isDeleted,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isRead, String? replyToMessageId, Message? replyToMessage,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isEdited, String? deletedFor, List<Reaction> reactions,@JsonKey(unknownEnumValue: MessageSendStatus.sent) MessageSendStatus sendStatus,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool localOnly,@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? deliveredAt
});


@override $MessageCopyWith<$Res>? get replyToMessage;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = null,Object? messageType = null,Object? mediaUrl = freezed,Object? localMediaPath = freezed,Object? metadata = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? isRead = null,Object? replyToMessageId = freezed,Object? replyToMessage = freezed,Object? isEdited = null,Object? deletedFor = freezed,Object? reactions = null,Object? sendStatus = null,Object? localOnly = null,Object? deliveredAt = freezed,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,localMediaPath: freezed == localMediaPath ? _self.localMediaPath : localMediaPath // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as Message?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,deletedFor: freezed == deletedFor ? _self.deletedFor : deletedFor // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<Reaction>,sendStatus: null == sendStatus ? _self.sendStatus : sendStatus // ignore: cast_nullable_to_non_nullable
as MessageSendStatus,localOnly: null == localOnly ? _self.localOnly : localOnly // ignore: cast_nullable_to_non_nullable
as bool,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get replyToMessage {
    if (_self.replyToMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.replyToMessage!, (value) {
    return _then(_self.copyWith(replyToMessage: value));
  });
}
}

// dart format on

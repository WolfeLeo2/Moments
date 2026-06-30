// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MomentComment {

@JsonKey(includeToJson: false) String get id; String get momentId; String get userId; String get content;@JsonKey(includeToJson: false) DateTime get createdAt;@JsonKey(includeToJson: false) DateTime get updatedAt;@JsonKey(includeToJson: false) String? get displayName;@JsonKey(includeToJson: false) String? get avatarUrl;
/// Create a copy of MomentComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentCommentCopyWith<MomentComment> get copyWith => _$MomentCommentCopyWithImpl<MomentComment>(this as MomentComment, _$identity);

  /// Serializes this MomentComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MomentComment&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,content,createdAt,updatedAt,displayName,avatarUrl);

@override
String toString() {
  return 'MomentComment(id: $id, momentId: $momentId, userId: $userId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $MomentCommentCopyWith<$Res>  {
  factory $MomentCommentCopyWith(MomentComment value, $Res Function(MomentComment) _then) = _$MomentCommentCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String momentId, String userId, String content,@JsonKey(includeToJson: false) DateTime createdAt,@JsonKey(includeToJson: false) DateTime updatedAt,@JsonKey(includeToJson: false) String? displayName,@JsonKey(includeToJson: false) String? avatarUrl
});




}
/// @nodoc
class _$MomentCommentCopyWithImpl<$Res>
    implements $MomentCommentCopyWith<$Res> {
  _$MomentCommentCopyWithImpl(this._self, this._then);

  final MomentComment _self;
  final $Res Function(MomentComment) _then;

/// Create a copy of MomentComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MomentComment].
extension MomentCommentPatterns on MomentComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MomentComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MomentComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MomentComment value)  $default,){
final _that = this;
switch (_that) {
case _MomentComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MomentComment value)?  $default,){
final _that = this;
switch (_that) {
case _MomentComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String momentId,  String userId,  String content, @JsonKey(includeToJson: false)  DateTime createdAt, @JsonKey(includeToJson: false)  DateTime updatedAt, @JsonKey(includeToJson: false)  String? displayName, @JsonKey(includeToJson: false)  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MomentComment() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.content,_that.createdAt,_that.updatedAt,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String momentId,  String userId,  String content, @JsonKey(includeToJson: false)  DateTime createdAt, @JsonKey(includeToJson: false)  DateTime updatedAt, @JsonKey(includeToJson: false)  String? displayName, @JsonKey(includeToJson: false)  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _MomentComment():
return $default(_that.id,_that.momentId,_that.userId,_that.content,_that.createdAt,_that.updatedAt,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String momentId,  String userId,  String content, @JsonKey(includeToJson: false)  DateTime createdAt, @JsonKey(includeToJson: false)  DateTime updatedAt, @JsonKey(includeToJson: false)  String? displayName, @JsonKey(includeToJson: false)  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _MomentComment() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.content,_that.createdAt,_that.updatedAt,_that.displayName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _MomentComment implements MomentComment {
  const _MomentComment({@JsonKey(includeToJson: false) required this.id, required this.momentId, required this.userId, required this.content, @JsonKey(includeToJson: false) required this.createdAt, @JsonKey(includeToJson: false) required this.updatedAt, @JsonKey(includeToJson: false) this.displayName, @JsonKey(includeToJson: false) this.avatarUrl});
  factory _MomentComment.fromJson(Map<String, dynamic> json) => _$MomentCommentFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String momentId;
@override final  String userId;
@override final  String content;
@override@JsonKey(includeToJson: false) final  DateTime createdAt;
@override@JsonKey(includeToJson: false) final  DateTime updatedAt;
@override@JsonKey(includeToJson: false) final  String? displayName;
@override@JsonKey(includeToJson: false) final  String? avatarUrl;

/// Create a copy of MomentComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentCommentCopyWith<_MomentComment> get copyWith => __$MomentCommentCopyWithImpl<_MomentComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MomentCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MomentComment&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,content,createdAt,updatedAt,displayName,avatarUrl);

@override
String toString() {
  return 'MomentComment(id: $id, momentId: $momentId, userId: $userId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$MomentCommentCopyWith<$Res> implements $MomentCommentCopyWith<$Res> {
  factory _$MomentCommentCopyWith(_MomentComment value, $Res Function(_MomentComment) _then) = __$MomentCommentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String momentId, String userId, String content,@JsonKey(includeToJson: false) DateTime createdAt,@JsonKey(includeToJson: false) DateTime updatedAt,@JsonKey(includeToJson: false) String? displayName,@JsonKey(includeToJson: false) String? avatarUrl
});




}
/// @nodoc
class __$MomentCommentCopyWithImpl<$Res>
    implements _$MomentCommentCopyWith<$Res> {
  __$MomentCommentCopyWithImpl(this._self, this._then);

  final _MomentComment _self;
  final $Res Function(_MomentComment) _then;

/// Create a copy of MomentComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? displayName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_MomentComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

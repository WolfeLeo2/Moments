// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment_reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MomentReaction {

 String get id; String get momentId; String get userId; String get emoji;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get createdAt;
/// Create a copy of MomentReaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentReactionCopyWith<MomentReaction> get copyWith => _$MomentReactionCopyWithImpl<MomentReaction>(this as MomentReaction, _$identity);

  /// Serializes this MomentReaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MomentReaction&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,emoji,createdAt);

@override
String toString() {
  return 'MomentReaction(id: $id, momentId: $momentId, userId: $userId, emoji: $emoji, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MomentReactionCopyWith<$Res>  {
  factory $MomentReactionCopyWith(MomentReaction value, $Res Function(MomentReaction) _then) = _$MomentReactionCopyWithImpl;
@useResult
$Res call({
 String id, String momentId, String userId, String emoji,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt
});




}
/// @nodoc
class _$MomentReactionCopyWithImpl<$Res>
    implements $MomentReactionCopyWith<$Res> {
  _$MomentReactionCopyWithImpl(this._self, this._then);

  final MomentReaction _self;
  final $Res Function(MomentReaction) _then;

/// Create a copy of MomentReaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? emoji = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MomentReaction].
extension MomentReactionPatterns on MomentReaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MomentReaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MomentReaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MomentReaction value)  $default,){
final _that = this;
switch (_that) {
case _MomentReaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MomentReaction value)?  $default,){
final _that = this;
switch (_that) {
case _MomentReaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String momentId,  String userId,  String emoji, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MomentReaction() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.emoji,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String momentId,  String userId,  String emoji, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MomentReaction():
return $default(_that.id,_that.momentId,_that.userId,_that.emoji,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String momentId,  String userId,  String emoji, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MomentReaction() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.emoji,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _MomentReaction implements MomentReaction {
  const _MomentReaction({required this.id, required this.momentId, required this.userId, required this.emoji, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.createdAt});
  factory _MomentReaction.fromJson(Map<String, dynamic> json) => _$MomentReactionFromJson(json);

@override final  String id;
@override final  String momentId;
@override final  String userId;
@override final  String emoji;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime createdAt;

/// Create a copy of MomentReaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentReactionCopyWith<_MomentReaction> get copyWith => __$MomentReactionCopyWithImpl<_MomentReaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MomentReactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MomentReaction&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,emoji,createdAt);

@override
String toString() {
  return 'MomentReaction(id: $id, momentId: $momentId, userId: $userId, emoji: $emoji, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MomentReactionCopyWith<$Res> implements $MomentReactionCopyWith<$Res> {
  factory _$MomentReactionCopyWith(_MomentReaction value, $Res Function(_MomentReaction) _then) = __$MomentReactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String momentId, String userId, String emoji,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt
});




}
/// @nodoc
class __$MomentReactionCopyWithImpl<$Res>
    implements _$MomentReactionCopyWith<$Res> {
  __$MomentReactionCopyWithImpl(this._self, this._then);

  final _MomentReaction _self;
  final $Res Function(_MomentReaction) _then;

/// Create a copy of MomentReaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? emoji = null,Object? createdAt = null,}) {
  return _then(_MomentReaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

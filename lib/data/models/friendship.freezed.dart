// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friendship.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Friendship {

 String get id; String get userId; String get friendId;@JsonKey(unknownEnumValue: FriendshipStatus.pending) FriendshipStatus get status;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get requestedAt;@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get respondedAt;
/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendshipCopyWith<Friendship> get copyWith => _$FriendshipCopyWithImpl<Friendship>(this as Friendship, _$identity);

  /// Serializes this Friendship to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friendship&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.friendId, friendId) || other.friendId == friendId)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,friendId,status,requestedAt,respondedAt);

@override
String toString() {
  return 'Friendship(id: $id, userId: $userId, friendId: $friendId, status: $status, requestedAt: $requestedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $FriendshipCopyWith<$Res>  {
  factory $FriendshipCopyWith(Friendship value, $Res Function(Friendship) _then) = _$FriendshipCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String friendId,@JsonKey(unknownEnumValue: FriendshipStatus.pending) FriendshipStatus status,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime requestedAt,@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? respondedAt
});




}
/// @nodoc
class _$FriendshipCopyWithImpl<$Res>
    implements $FriendshipCopyWith<$Res> {
  _$FriendshipCopyWithImpl(this._self, this._then);

  final Friendship _self;
  final $Res Function(Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? friendId = null,Object? status = null,Object? requestedAt = null,Object? respondedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,friendId: null == friendId ? _self.friendId : friendId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendshipStatus,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Friendship].
extension FriendshipPatterns on Friendship {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friendship value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friendship value)  $default,){
final _that = this;
switch (_that) {
case _Friendship():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friendship value)?  $default,){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String friendId, @JsonKey(unknownEnumValue: FriendshipStatus.pending)  FriendshipStatus status, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime requestedAt, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.id,_that.userId,_that.friendId,_that.status,_that.requestedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String friendId, @JsonKey(unknownEnumValue: FriendshipStatus.pending)  FriendshipStatus status, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime requestedAt, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _Friendship():
return $default(_that.id,_that.userId,_that.friendId,_that.status,_that.requestedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String friendId, @JsonKey(unknownEnumValue: FriendshipStatus.pending)  FriendshipStatus status, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime requestedAt, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.id,_that.userId,_that.friendId,_that.status,_that.requestedAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Friendship implements Friendship {
  const _Friendship({required this.id, required this.userId, required this.friendId, @JsonKey(unknownEnumValue: FriendshipStatus.pending) required this.status, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.requestedAt, @JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) this.respondedAt});
  factory _Friendship.fromJson(Map<String, dynamic> json) => _$FriendshipFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String friendId;
@override@JsonKey(unknownEnumValue: FriendshipStatus.pending) final  FriendshipStatus status;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime requestedAt;
@override@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? respondedAt;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendshipCopyWith<_Friendship> get copyWith => __$FriendshipCopyWithImpl<_Friendship>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendshipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friendship&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.friendId, friendId) || other.friendId == friendId)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,friendId,status,requestedAt,respondedAt);

@override
String toString() {
  return 'Friendship(id: $id, userId: $userId, friendId: $friendId, status: $status, requestedAt: $requestedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$FriendshipCopyWith<$Res> implements $FriendshipCopyWith<$Res> {
  factory _$FriendshipCopyWith(_Friendship value, $Res Function(_Friendship) _then) = __$FriendshipCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String friendId,@JsonKey(unknownEnumValue: FriendshipStatus.pending) FriendshipStatus status,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime requestedAt,@JsonKey(fromJson: nullableLocalDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? respondedAt
});




}
/// @nodoc
class __$FriendshipCopyWithImpl<$Res>
    implements _$FriendshipCopyWith<$Res> {
  __$FriendshipCopyWithImpl(this._self, this._then);

  final _Friendship _self;
  final $Res Function(_Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? friendId = null,Object? status = null,Object? requestedAt = null,Object? respondedAt = freezed,}) {
  return _then(_Friendship(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,friendId: null == friendId ? _self.friendId : friendId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendshipStatus,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

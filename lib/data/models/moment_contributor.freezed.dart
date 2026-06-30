// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment_contributor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MomentContributor {

 String get id; String get momentId; String get userId; ContributorRole get role; DateTime get invitedAt; DateTime? get acceptedAt; String? get username; String? get displayName; String? get avatarUrl; String? get groupTitle; String? get inviterUsername; String? get inviterAvatarUrl;
/// Create a copy of MomentContributor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentContributorCopyWith<MomentContributor> get copyWith => _$MomentContributorCopyWithImpl<MomentContributor>(this as MomentContributor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MomentContributor&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.groupTitle, groupTitle) || other.groupTitle == groupTitle)&&(identical(other.inviterUsername, inviterUsername) || other.inviterUsername == inviterUsername)&&(identical(other.inviterAvatarUrl, inviterAvatarUrl) || other.inviterAvatarUrl == inviterAvatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,role,invitedAt,acceptedAt,username,displayName,avatarUrl,groupTitle,inviterUsername,inviterAvatarUrl);

@override
String toString() {
  return 'MomentContributor(id: $id, momentId: $momentId, userId: $userId, role: $role, invitedAt: $invitedAt, acceptedAt: $acceptedAt, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, groupTitle: $groupTitle, inviterUsername: $inviterUsername, inviterAvatarUrl: $inviterAvatarUrl)';
}


}

/// @nodoc
abstract mixin class $MomentContributorCopyWith<$Res>  {
  factory $MomentContributorCopyWith(MomentContributor value, $Res Function(MomentContributor) _then) = _$MomentContributorCopyWithImpl;
@useResult
$Res call({
 String id, String momentId, String userId, ContributorRole role, DateTime invitedAt, DateTime? acceptedAt, String? username, String? displayName, String? avatarUrl, String? groupTitle, String? inviterUsername, String? inviterAvatarUrl
});




}
/// @nodoc
class _$MomentContributorCopyWithImpl<$Res>
    implements $MomentContributorCopyWith<$Res> {
  _$MomentContributorCopyWithImpl(this._self, this._then);

  final MomentContributor _self;
  final $Res Function(MomentContributor) _then;

/// Create a copy of MomentContributor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? role = null,Object? invitedAt = null,Object? acceptedAt = freezed,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? groupTitle = freezed,Object? inviterUsername = freezed,Object? inviterAvatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ContributorRole,invitedAt: null == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,groupTitle: freezed == groupTitle ? _self.groupTitle : groupTitle // ignore: cast_nullable_to_non_nullable
as String?,inviterUsername: freezed == inviterUsername ? _self.inviterUsername : inviterUsername // ignore: cast_nullable_to_non_nullable
as String?,inviterAvatarUrl: freezed == inviterAvatarUrl ? _self.inviterAvatarUrl : inviterAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MomentContributor].
extension MomentContributorPatterns on MomentContributor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MomentContributor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MomentContributor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MomentContributor value)  $default,){
final _that = this;
switch (_that) {
case _MomentContributor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MomentContributor value)?  $default,){
final _that = this;
switch (_that) {
case _MomentContributor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String momentId,  String userId,  ContributorRole role,  DateTime invitedAt,  DateTime? acceptedAt,  String? username,  String? displayName,  String? avatarUrl,  String? groupTitle,  String? inviterUsername,  String? inviterAvatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MomentContributor() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.role,_that.invitedAt,_that.acceptedAt,_that.username,_that.displayName,_that.avatarUrl,_that.groupTitle,_that.inviterUsername,_that.inviterAvatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String momentId,  String userId,  ContributorRole role,  DateTime invitedAt,  DateTime? acceptedAt,  String? username,  String? displayName,  String? avatarUrl,  String? groupTitle,  String? inviterUsername,  String? inviterAvatarUrl)  $default,) {final _that = this;
switch (_that) {
case _MomentContributor():
return $default(_that.id,_that.momentId,_that.userId,_that.role,_that.invitedAt,_that.acceptedAt,_that.username,_that.displayName,_that.avatarUrl,_that.groupTitle,_that.inviterUsername,_that.inviterAvatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String momentId,  String userId,  ContributorRole role,  DateTime invitedAt,  DateTime? acceptedAt,  String? username,  String? displayName,  String? avatarUrl,  String? groupTitle,  String? inviterUsername,  String? inviterAvatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _MomentContributor() when $default != null:
return $default(_that.id,_that.momentId,_that.userId,_that.role,_that.invitedAt,_that.acceptedAt,_that.username,_that.displayName,_that.avatarUrl,_that.groupTitle,_that.inviterUsername,_that.inviterAvatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _MomentContributor extends MomentContributor {
  const _MomentContributor({required this.id, required this.momentId, required this.userId, required this.role, required this.invitedAt, this.acceptedAt, this.username, this.displayName, this.avatarUrl, this.groupTitle, this.inviterUsername, this.inviterAvatarUrl}): super._();
  

@override final  String id;
@override final  String momentId;
@override final  String userId;
@override final  ContributorRole role;
@override final  DateTime invitedAt;
@override final  DateTime? acceptedAt;
@override final  String? username;
@override final  String? displayName;
@override final  String? avatarUrl;
@override final  String? groupTitle;
@override final  String? inviterUsername;
@override final  String? inviterAvatarUrl;

/// Create a copy of MomentContributor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentContributorCopyWith<_MomentContributor> get copyWith => __$MomentContributorCopyWithImpl<_MomentContributor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MomentContributor&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.groupTitle, groupTitle) || other.groupTitle == groupTitle)&&(identical(other.inviterUsername, inviterUsername) || other.inviterUsername == inviterUsername)&&(identical(other.inviterAvatarUrl, inviterAvatarUrl) || other.inviterAvatarUrl == inviterAvatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,momentId,userId,role,invitedAt,acceptedAt,username,displayName,avatarUrl,groupTitle,inviterUsername,inviterAvatarUrl);

@override
String toString() {
  return 'MomentContributor(id: $id, momentId: $momentId, userId: $userId, role: $role, invitedAt: $invitedAt, acceptedAt: $acceptedAt, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, groupTitle: $groupTitle, inviterUsername: $inviterUsername, inviterAvatarUrl: $inviterAvatarUrl)';
}


}

/// @nodoc
abstract mixin class _$MomentContributorCopyWith<$Res> implements $MomentContributorCopyWith<$Res> {
  factory _$MomentContributorCopyWith(_MomentContributor value, $Res Function(_MomentContributor) _then) = __$MomentContributorCopyWithImpl;
@override @useResult
$Res call({
 String id, String momentId, String userId, ContributorRole role, DateTime invitedAt, DateTime? acceptedAt, String? username, String? displayName, String? avatarUrl, String? groupTitle, String? inviterUsername, String? inviterAvatarUrl
});




}
/// @nodoc
class __$MomentContributorCopyWithImpl<$Res>
    implements _$MomentContributorCopyWith<$Res> {
  __$MomentContributorCopyWithImpl(this._self, this._then);

  final _MomentContributor _self;
  final $Res Function(_MomentContributor) _then;

/// Create a copy of MomentContributor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? momentId = null,Object? userId = null,Object? role = null,Object? invitedAt = null,Object? acceptedAt = freezed,Object? username = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? groupTitle = freezed,Object? inviterUsername = freezed,Object? inviterAvatarUrl = freezed,}) {
  return _then(_MomentContributor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ContributorRole,invitedAt: null == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as DateTime,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,groupTitle: freezed == groupTitle ? _self.groupTitle : groupTitle // ignore: cast_nullable_to_non_nullable
as String?,inviterUsername: freezed == inviterUsername ? _self.inviterUsername : inviterUsername // ignore: cast_nullable_to_non_nullable
as String?,inviterAvatarUrl: freezed == inviterAvatarUrl ? _self.inviterAvatarUrl : inviterAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

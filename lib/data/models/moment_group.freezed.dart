// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MomentGroup {

 String get id; String get title;/// Populated after construction — excluded from JSON serialization.
 List<Moment> get moments; double get latitude; double get longitude; String? get createdBy; DateTime get createdAt; DateTime get updatedAt; bool get isPrivate;
/// Create a copy of MomentGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentGroupCopyWith<MomentGroup> get copyWith => _$MomentGroupCopyWithImpl<MomentGroup>(this as MomentGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MomentGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.moments, moments)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(moments),latitude,longitude,createdBy,createdAt,updatedAt,isPrivate);

@override
String toString() {
  return 'MomentGroup(id: $id, title: $title, moments: $moments, latitude: $latitude, longitude: $longitude, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, isPrivate: $isPrivate)';
}


}

/// @nodoc
abstract mixin class $MomentGroupCopyWith<$Res>  {
  factory $MomentGroupCopyWith(MomentGroup value, $Res Function(MomentGroup) _then) = _$MomentGroupCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<Moment> moments, double latitude, double longitude, String? createdBy, DateTime createdAt, DateTime updatedAt, bool isPrivate
});




}
/// @nodoc
class _$MomentGroupCopyWithImpl<$Res>
    implements $MomentGroupCopyWith<$Res> {
  _$MomentGroupCopyWithImpl(this._self, this._then);

  final MomentGroup _self;
  final $Res Function(MomentGroup) _then;

/// Create a copy of MomentGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? moments = null,Object? latitude = null,Object? longitude = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isPrivate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,moments: null == moments ? _self.moments : moments // ignore: cast_nullable_to_non_nullable
as List<Moment>,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MomentGroup].
extension MomentGroupPatterns on MomentGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MomentGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MomentGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MomentGroup value)  $default,){
final _that = this;
switch (_that) {
case _MomentGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MomentGroup value)?  $default,){
final _that = this;
switch (_that) {
case _MomentGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<Moment> moments,  double latitude,  double longitude,  String? createdBy,  DateTime createdAt,  DateTime updatedAt,  bool isPrivate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MomentGroup() when $default != null:
return $default(_that.id,_that.title,_that.moments,_that.latitude,_that.longitude,_that.createdBy,_that.createdAt,_that.updatedAt,_that.isPrivate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<Moment> moments,  double latitude,  double longitude,  String? createdBy,  DateTime createdAt,  DateTime updatedAt,  bool isPrivate)  $default,) {final _that = this;
switch (_that) {
case _MomentGroup():
return $default(_that.id,_that.title,_that.moments,_that.latitude,_that.longitude,_that.createdBy,_that.createdAt,_that.updatedAt,_that.isPrivate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<Moment> moments,  double latitude,  double longitude,  String? createdBy,  DateTime createdAt,  DateTime updatedAt,  bool isPrivate)?  $default,) {final _that = this;
switch (_that) {
case _MomentGroup() when $default != null:
return $default(_that.id,_that.title,_that.moments,_that.latitude,_that.longitude,_that.createdBy,_that.createdAt,_that.updatedAt,_that.isPrivate);case _:
  return null;

}
}

}

/// @nodoc


class _MomentGroup extends MomentGroup {
  const _MomentGroup({required this.id, required this.title, final  List<Moment> moments = const [], required this.latitude, required this.longitude, this.createdBy, required this.createdAt, required this.updatedAt, this.isPrivate = false}): _moments = moments,super._();
  

@override final  String id;
@override final  String title;
/// Populated after construction — excluded from JSON serialization.
 final  List<Moment> _moments;
/// Populated after construction — excluded from JSON serialization.
@override@JsonKey() List<Moment> get moments {
  if (_moments is EqualUnmodifiableListView) return _moments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moments);
}

@override final  double latitude;
@override final  double longitude;
@override final  String? createdBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isPrivate;

/// Create a copy of MomentGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentGroupCopyWith<_MomentGroup> get copyWith => __$MomentGroupCopyWithImpl<_MomentGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MomentGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._moments, _moments)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_moments),latitude,longitude,createdBy,createdAt,updatedAt,isPrivate);

@override
String toString() {
  return 'MomentGroup(id: $id, title: $title, moments: $moments, latitude: $latitude, longitude: $longitude, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, isPrivate: $isPrivate)';
}


}

/// @nodoc
abstract mixin class _$MomentGroupCopyWith<$Res> implements $MomentGroupCopyWith<$Res> {
  factory _$MomentGroupCopyWith(_MomentGroup value, $Res Function(_MomentGroup) _then) = __$MomentGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<Moment> moments, double latitude, double longitude, String? createdBy, DateTime createdAt, DateTime updatedAt, bool isPrivate
});




}
/// @nodoc
class __$MomentGroupCopyWithImpl<$Res>
    implements _$MomentGroupCopyWith<$Res> {
  __$MomentGroupCopyWithImpl(this._self, this._then);

  final _MomentGroup _self;
  final $Res Function(_MomentGroup) _then;

/// Create a copy of MomentGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? moments = null,Object? latitude = null,Object? longitude = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isPrivate = null,}) {
  return _then(_MomentGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,moments: null == moments ? _self._moments : moments // ignore: cast_nullable_to_non_nullable
as List<Moment>,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

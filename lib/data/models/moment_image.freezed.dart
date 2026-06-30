// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MomentImage {

 String get id; String get momentId; String? get imageUrl; String get mediaPath; String? get caption; int get displayOrder;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get createdAt;
/// Create a copy of MomentImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentImageCopyWith<MomentImage> get copyWith => _$MomentImageCopyWithImpl<MomentImage>(this as MomentImage, _$identity);

  /// Serializes this MomentImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MomentImage&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaPath, mediaPath) || other.mediaPath == mediaPath)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,imageUrl,mediaPath,caption,displayOrder,createdAt);

@override
String toString() {
  return 'MomentImage(id: $id, momentId: $momentId, imageUrl: $imageUrl, mediaPath: $mediaPath, caption: $caption, displayOrder: $displayOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MomentImageCopyWith<$Res>  {
  factory $MomentImageCopyWith(MomentImage value, $Res Function(MomentImage) _then) = _$MomentImageCopyWithImpl;
@useResult
$Res call({
 String id, String momentId, String? imageUrl, String mediaPath, String? caption, int displayOrder,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt
});




}
/// @nodoc
class _$MomentImageCopyWithImpl<$Res>
    implements $MomentImageCopyWith<$Res> {
  _$MomentImageCopyWithImpl(this._self, this._then);

  final MomentImage _self;
  final $Res Function(MomentImage) _then;

/// Create a copy of MomentImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? momentId = null,Object? imageUrl = freezed,Object? mediaPath = null,Object? caption = freezed,Object? displayOrder = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaPath: null == mediaPath ? _self.mediaPath : mediaPath // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MomentImage].
extension MomentImagePatterns on MomentImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MomentImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MomentImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MomentImage value)  $default,){
final _that = this;
switch (_that) {
case _MomentImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MomentImage value)?  $default,){
final _that = this;
switch (_that) {
case _MomentImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String momentId,  String? imageUrl,  String mediaPath,  String? caption,  int displayOrder, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MomentImage() when $default != null:
return $default(_that.id,_that.momentId,_that.imageUrl,_that.mediaPath,_that.caption,_that.displayOrder,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String momentId,  String? imageUrl,  String mediaPath,  String? caption,  int displayOrder, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MomentImage():
return $default(_that.id,_that.momentId,_that.imageUrl,_that.mediaPath,_that.caption,_that.displayOrder,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String momentId,  String? imageUrl,  String mediaPath,  String? caption,  int displayOrder, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MomentImage() when $default != null:
return $default(_that.id,_that.momentId,_that.imageUrl,_that.mediaPath,_that.caption,_that.displayOrder,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _MomentImage implements MomentImage {
  const _MomentImage({required this.id, required this.momentId, this.imageUrl, required this.mediaPath, this.caption, this.displayOrder = 0, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.createdAt});
  factory _MomentImage.fromJson(Map<String, dynamic> json) => _$MomentImageFromJson(json);

@override final  String id;
@override final  String momentId;
@override final  String? imageUrl;
@override final  String mediaPath;
@override final  String? caption;
@override@JsonKey() final  int displayOrder;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime createdAt;

/// Create a copy of MomentImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentImageCopyWith<_MomentImage> get copyWith => __$MomentImageCopyWithImpl<_MomentImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MomentImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MomentImage&&(identical(other.id, id) || other.id == id)&&(identical(other.momentId, momentId) || other.momentId == momentId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaPath, mediaPath) || other.mediaPath == mediaPath)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,momentId,imageUrl,mediaPath,caption,displayOrder,createdAt);

@override
String toString() {
  return 'MomentImage(id: $id, momentId: $momentId, imageUrl: $imageUrl, mediaPath: $mediaPath, caption: $caption, displayOrder: $displayOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MomentImageCopyWith<$Res> implements $MomentImageCopyWith<$Res> {
  factory _$MomentImageCopyWith(_MomentImage value, $Res Function(_MomentImage) _then) = __$MomentImageCopyWithImpl;
@override @useResult
$Res call({
 String id, String momentId, String? imageUrl, String mediaPath, String? caption, int displayOrder,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt
});




}
/// @nodoc
class __$MomentImageCopyWithImpl<$Res>
    implements _$MomentImageCopyWith<$Res> {
  __$MomentImageCopyWithImpl(this._self, this._then);

  final _MomentImage _self;
  final $Res Function(_MomentImage) _then;

/// Create a copy of MomentImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? momentId = null,Object? imageUrl = freezed,Object? mediaPath = null,Object? caption = freezed,Object? displayOrder = null,Object? createdAt = null,}) {
  return _then(_MomentImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,momentId: null == momentId ? _self.momentId : momentId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaPath: null == mediaPath ? _self.mediaPath : mediaPath // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

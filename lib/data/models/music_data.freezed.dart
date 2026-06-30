// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicData {

 MusicType get type; String? get trackId; String get url; String get title; String get artist; String? get albumArt;
/// Create a copy of MusicData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicDataCopyWith<MusicData> get copyWith => _$MusicDataCopyWithImpl<MusicData>(this as MusicData, _$identity);

  /// Serializes this MusicData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicData&&(identical(other.type, type) || other.type == type)&&(identical(other.trackId, trackId) || other.trackId == trackId)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.albumArt, albumArt) || other.albumArt == albumArt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,trackId,url,title,artist,albumArt);



}

/// @nodoc
abstract mixin class $MusicDataCopyWith<$Res>  {
  factory $MusicDataCopyWith(MusicData value, $Res Function(MusicData) _then) = _$MusicDataCopyWithImpl;
@useResult
$Res call({
 MusicType type, String? trackId, String url, String title, String artist, String? albumArt
});




}
/// @nodoc
class _$MusicDataCopyWithImpl<$Res>
    implements $MusicDataCopyWith<$Res> {
  _$MusicDataCopyWithImpl(this._self, this._then);

  final MusicData _self;
  final $Res Function(MusicData) _then;

/// Create a copy of MusicData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? trackId = freezed,Object? url = null,Object? title = null,Object? artist = null,Object? albumArt = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MusicType,trackId: freezed == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,albumArt: freezed == albumArt ? _self.albumArt : albumArt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicData].
extension MusicDataPatterns on MusicData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicData value)  $default,){
final _that = this;
switch (_that) {
case _MusicData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicData value)?  $default,){
final _that = this;
switch (_that) {
case _MusicData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MusicType type,  String? trackId,  String url,  String title,  String artist,  String? albumArt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicData() when $default != null:
return $default(_that.type,_that.trackId,_that.url,_that.title,_that.artist,_that.albumArt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MusicType type,  String? trackId,  String url,  String title,  String artist,  String? albumArt)  $default,) {final _that = this;
switch (_that) {
case _MusicData():
return $default(_that.type,_that.trackId,_that.url,_that.title,_that.artist,_that.albumArt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MusicType type,  String? trackId,  String url,  String title,  String artist,  String? albumArt)?  $default,) {final _that = this;
switch (_that) {
case _MusicData() when $default != null:
return $default(_that.type,_that.trackId,_that.url,_that.title,_that.artist,_that.albumArt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _MusicData extends MusicData {
  const _MusicData({required this.type, this.trackId, this.url = '', this.title = 'Unknown', this.artist = 'Unknown', this.albumArt}): super._();
  factory _MusicData.fromJson(Map<String, dynamic> json) => _$MusicDataFromJson(json);

@override final  MusicType type;
@override final  String? trackId;
@override@JsonKey() final  String url;
@override@JsonKey() final  String title;
@override@JsonKey() final  String artist;
@override final  String? albumArt;

/// Create a copy of MusicData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicDataCopyWith<_MusicData> get copyWith => __$MusicDataCopyWithImpl<_MusicData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicData&&(identical(other.type, type) || other.type == type)&&(identical(other.trackId, trackId) || other.trackId == trackId)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.albumArt, albumArt) || other.albumArt == albumArt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,trackId,url,title,artist,albumArt);



}

/// @nodoc
abstract mixin class _$MusicDataCopyWith<$Res> implements $MusicDataCopyWith<$Res> {
  factory _$MusicDataCopyWith(_MusicData value, $Res Function(_MusicData) _then) = __$MusicDataCopyWithImpl;
@override @useResult
$Res call({
 MusicType type, String? trackId, String url, String title, String artist, String? albumArt
});




}
/// @nodoc
class __$MusicDataCopyWithImpl<$Res>
    implements _$MusicDataCopyWith<$Res> {
  __$MusicDataCopyWithImpl(this._self, this._then);

  final _MusicData _self;
  final $Res Function(_MusicData) _then;

/// Create a copy of MusicData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? trackId = freezed,Object? url = null,Object? title = null,Object? artist = null,Object? albumArt = freezed,}) {
  return _then(_MusicData(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MusicType,trackId: freezed == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,albumArt: freezed == albumArt ? _self.albumArt : albumArt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

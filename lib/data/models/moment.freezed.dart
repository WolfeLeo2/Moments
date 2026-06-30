// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Moment {

 String get id; String get title; String get location; double get latitude; double get longitude; String? get imageUrl; String? get mediaPath; String? get caption; String get mediaType; int? get duration; String? get thumbnailPath;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get createdAt;@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime get timestamp; String? get userId; String? get description; String get momentGroupId;@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool get isPrivate; String? get audioPath; int? get audioDuration;@MusicDataConverter() MusicData? get musicData;@JsonKey(includeFromJson: false, includeToJson: false) String? get localMediaPath;@JsonKey(includeFromJson: false, includeToJson: false) String? get localThumbnailPath;
/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MomentCopyWith<Moment> get copyWith => _$MomentCopyWithImpl<Moment>(this as Moment, _$identity);

  /// Serializes this Moment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Moment&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaPath, mediaPath) || other.mediaPath == mediaPath)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.description, description) || other.description == description)&&(identical(other.momentGroupId, momentGroupId) || other.momentGroupId == momentGroupId)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.audioDuration, audioDuration) || other.audioDuration == audioDuration)&&(identical(other.musicData, musicData) || other.musicData == musicData)&&(identical(other.localMediaPath, localMediaPath) || other.localMediaPath == localMediaPath)&&(identical(other.localThumbnailPath, localThumbnailPath) || other.localThumbnailPath == localThumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,location,latitude,longitude,imageUrl,mediaPath,caption,mediaType,duration,thumbnailPath,createdAt,timestamp,userId,description,momentGroupId,isPrivate,audioPath,audioDuration,musicData,localMediaPath,localThumbnailPath]);



}

/// @nodoc
abstract mixin class $MomentCopyWith<$Res>  {
  factory $MomentCopyWith(Moment value, $Res Function(Moment) _then) = _$MomentCopyWithImpl;
@useResult
$Res call({
 String id, String title, String location, double latitude, double longitude, String? imageUrl, String? mediaPath, String? caption, String mediaType, int? duration, String? thumbnailPath,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime timestamp, String? userId, String? description, String momentGroupId,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isPrivate, String? audioPath, int? audioDuration,@MusicDataConverter() MusicData? musicData,@JsonKey(includeFromJson: false, includeToJson: false) String? localMediaPath,@JsonKey(includeFromJson: false, includeToJson: false) String? localThumbnailPath
});


$MusicDataCopyWith<$Res>? get musicData;

}
/// @nodoc
class _$MomentCopyWithImpl<$Res>
    implements $MomentCopyWith<$Res> {
  _$MomentCopyWithImpl(this._self, this._then);

  final Moment _self;
  final $Res Function(Moment) _then;

/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? location = null,Object? latitude = null,Object? longitude = null,Object? imageUrl = freezed,Object? mediaPath = freezed,Object? caption = freezed,Object? mediaType = null,Object? duration = freezed,Object? thumbnailPath = freezed,Object? createdAt = null,Object? timestamp = null,Object? userId = freezed,Object? description = freezed,Object? momentGroupId = null,Object? isPrivate = null,Object? audioPath = freezed,Object? audioDuration = freezed,Object? musicData = freezed,Object? localMediaPath = freezed,Object? localThumbnailPath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaPath: freezed == mediaPath ? _self.mediaPath : mediaPath // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,momentGroupId: null == momentGroupId ? _self.momentGroupId : momentGroupId // ignore: cast_nullable_to_non_nullable
as String,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,audioDuration: freezed == audioDuration ? _self.audioDuration : audioDuration // ignore: cast_nullable_to_non_nullable
as int?,musicData: freezed == musicData ? _self.musicData : musicData // ignore: cast_nullable_to_non_nullable
as MusicData?,localMediaPath: freezed == localMediaPath ? _self.localMediaPath : localMediaPath // ignore: cast_nullable_to_non_nullable
as String?,localThumbnailPath: freezed == localThumbnailPath ? _self.localThumbnailPath : localThumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicDataCopyWith<$Res>? get musicData {
    if (_self.musicData == null) {
    return null;
  }

  return $MusicDataCopyWith<$Res>(_self.musicData!, (value) {
    return _then(_self.copyWith(musicData: value));
  });
}
}


/// Adds pattern-matching-related methods to [Moment].
extension MomentPatterns on Moment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Moment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Moment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Moment value)  $default,){
final _that = this;
switch (_that) {
case _Moment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Moment value)?  $default,){
final _that = this;
switch (_that) {
case _Moment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String location,  double latitude,  double longitude,  String? imageUrl,  String? mediaPath,  String? caption,  String mediaType,  int? duration,  String? thumbnailPath, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime timestamp,  String? userId,  String? description,  String momentGroupId, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isPrivate,  String? audioPath,  int? audioDuration, @MusicDataConverter()  MusicData? musicData, @JsonKey(includeFromJson: false, includeToJson: false)  String? localMediaPath, @JsonKey(includeFromJson: false, includeToJson: false)  String? localThumbnailPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Moment() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.latitude,_that.longitude,_that.imageUrl,_that.mediaPath,_that.caption,_that.mediaType,_that.duration,_that.thumbnailPath,_that.createdAt,_that.timestamp,_that.userId,_that.description,_that.momentGroupId,_that.isPrivate,_that.audioPath,_that.audioDuration,_that.musicData,_that.localMediaPath,_that.localThumbnailPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String location,  double latitude,  double longitude,  String? imageUrl,  String? mediaPath,  String? caption,  String mediaType,  int? duration,  String? thumbnailPath, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime timestamp,  String? userId,  String? description,  String momentGroupId, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isPrivate,  String? audioPath,  int? audioDuration, @MusicDataConverter()  MusicData? musicData, @JsonKey(includeFromJson: false, includeToJson: false)  String? localMediaPath, @JsonKey(includeFromJson: false, includeToJson: false)  String? localThumbnailPath)  $default,) {final _that = this;
switch (_that) {
case _Moment():
return $default(_that.id,_that.title,_that.location,_that.latitude,_that.longitude,_that.imageUrl,_that.mediaPath,_that.caption,_that.mediaType,_that.duration,_that.thumbnailPath,_that.createdAt,_that.timestamp,_that.userId,_that.description,_that.momentGroupId,_that.isPrivate,_that.audioPath,_that.audioDuration,_that.musicData,_that.localMediaPath,_that.localThumbnailPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String location,  double latitude,  double longitude,  String? imageUrl,  String? mediaPath,  String? caption,  String mediaType,  int? duration,  String? thumbnailPath, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)  DateTime timestamp,  String? userId,  String? description,  String momentGroupId, @JsonKey(fromJson: boolFromJson, toJson: boolToJson)  bool isPrivate,  String? audioPath,  int? audioDuration, @MusicDataConverter()  MusicData? musicData, @JsonKey(includeFromJson: false, includeToJson: false)  String? localMediaPath, @JsonKey(includeFromJson: false, includeToJson: false)  String? localThumbnailPath)?  $default,) {final _that = this;
switch (_that) {
case _Moment() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.latitude,_that.longitude,_that.imageUrl,_that.mediaPath,_that.caption,_that.mediaType,_that.duration,_that.thumbnailPath,_that.createdAt,_that.timestamp,_that.userId,_that.description,_that.momentGroupId,_that.isPrivate,_that.audioPath,_that.audioDuration,_that.musicData,_that.localMediaPath,_that.localThumbnailPath);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Moment extends Moment {
  const _Moment({required this.id, this.title = 'Untitled', this.location = 'Unknown', required this.latitude, required this.longitude, this.imageUrl, this.mediaPath, this.caption, this.mediaType = 'image', this.duration, this.thumbnailPath, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.createdAt, @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) required this.timestamp, this.userId, this.description, required this.momentGroupId, @JsonKey(fromJson: boolFromJson, toJson: boolToJson) this.isPrivate = false, this.audioPath, this.audioDuration, @MusicDataConverter() this.musicData, @JsonKey(includeFromJson: false, includeToJson: false) this.localMediaPath, @JsonKey(includeFromJson: false, includeToJson: false) this.localThumbnailPath}): super._();
  factory _Moment.fromJson(Map<String, dynamic> json) => _$MomentFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String location;
@override final  double latitude;
@override final  double longitude;
@override final  String? imageUrl;
@override final  String? mediaPath;
@override final  String? caption;
@override@JsonKey() final  String mediaType;
@override final  int? duration;
@override final  String? thumbnailPath;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime createdAt;
@override@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) final  DateTime timestamp;
@override final  String? userId;
@override final  String? description;
@override final  String momentGroupId;
@override@JsonKey(fromJson: boolFromJson, toJson: boolToJson) final  bool isPrivate;
@override final  String? audioPath;
@override final  int? audioDuration;
@override@MusicDataConverter() final  MusicData? musicData;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? localMediaPath;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? localThumbnailPath;

/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MomentCopyWith<_Moment> get copyWith => __$MomentCopyWithImpl<_Moment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MomentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Moment&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.mediaPath, mediaPath) || other.mediaPath == mediaPath)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.description, description) || other.description == description)&&(identical(other.momentGroupId, momentGroupId) || other.momentGroupId == momentGroupId)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.audioDuration, audioDuration) || other.audioDuration == audioDuration)&&(identical(other.musicData, musicData) || other.musicData == musicData)&&(identical(other.localMediaPath, localMediaPath) || other.localMediaPath == localMediaPath)&&(identical(other.localThumbnailPath, localThumbnailPath) || other.localThumbnailPath == localThumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,location,latitude,longitude,imageUrl,mediaPath,caption,mediaType,duration,thumbnailPath,createdAt,timestamp,userId,description,momentGroupId,isPrivate,audioPath,audioDuration,musicData,localMediaPath,localThumbnailPath]);



}

/// @nodoc
abstract mixin class _$MomentCopyWith<$Res> implements $MomentCopyWith<$Res> {
  factory _$MomentCopyWith(_Moment value, $Res Function(_Moment) _then) = __$MomentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String location, double latitude, double longitude, String? imageUrl, String? mediaPath, String? caption, String mediaType, int? duration, String? thumbnailPath,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson) DateTime timestamp, String? userId, String? description, String momentGroupId,@JsonKey(fromJson: boolFromJson, toJson: boolToJson) bool isPrivate, String? audioPath, int? audioDuration,@MusicDataConverter() MusicData? musicData,@JsonKey(includeFromJson: false, includeToJson: false) String? localMediaPath,@JsonKey(includeFromJson: false, includeToJson: false) String? localThumbnailPath
});


@override $MusicDataCopyWith<$Res>? get musicData;

}
/// @nodoc
class __$MomentCopyWithImpl<$Res>
    implements _$MomentCopyWith<$Res> {
  __$MomentCopyWithImpl(this._self, this._then);

  final _Moment _self;
  final $Res Function(_Moment) _then;

/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? location = null,Object? latitude = null,Object? longitude = null,Object? imageUrl = freezed,Object? mediaPath = freezed,Object? caption = freezed,Object? mediaType = null,Object? duration = freezed,Object? thumbnailPath = freezed,Object? createdAt = null,Object? timestamp = null,Object? userId = freezed,Object? description = freezed,Object? momentGroupId = null,Object? isPrivate = null,Object? audioPath = freezed,Object? audioDuration = freezed,Object? musicData = freezed,Object? localMediaPath = freezed,Object? localThumbnailPath = freezed,}) {
  return _then(_Moment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaPath: freezed == mediaPath ? _self.mediaPath : mediaPath // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,momentGroupId: null == momentGroupId ? _self.momentGroupId : momentGroupId // ignore: cast_nullable_to_non_nullable
as String,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,audioDuration: freezed == audioDuration ? _self.audioDuration : audioDuration // ignore: cast_nullable_to_non_nullable
as int?,musicData: freezed == musicData ? _self.musicData : musicData // ignore: cast_nullable_to_non_nullable
as MusicData?,localMediaPath: freezed == localMediaPath ? _self.localMediaPath : localMediaPath // ignore: cast_nullable_to_non_nullable
as String?,localThumbnailPath: freezed == localThumbnailPath ? _self.localThumbnailPath : localThumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Moment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicDataCopyWith<$Res>? get musicData {
    if (_self.musicData == null) {
    return null;
  }

  return $MusicDataCopyWith<$Res>(_self.musicData!, (value) {
    return _then(_self.copyWith(musicData: value));
  });
}
}

// dart format on

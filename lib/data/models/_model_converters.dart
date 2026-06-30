import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'music_data.dart';

DateTime localDateTimeFromJson(String s) => DateTime.parse(s).toLocal();

/// Handles SQLite integers (0/1) as well as Dart bools.
bool boolFromJson(dynamic value) => switch (value) {
      final bool b => b,
      final int i => i != 0,
      _ => false,
    };
bool boolToJson(bool value) => value;
String dateTimeToJson(DateTime d) => d.toIso8601String();
DateTime? nullableLocalDateTimeFromJson(String? s) =>
    s == null ? null : DateTime.parse(s).toLocal();
String? nullableDateTimeToJson(DateTime? d) => d?.toIso8601String();

class MusicDataConverter implements JsonConverter<MusicData?, dynamic> {
  const MusicDataConverter();

  @override
  MusicData? fromJson(dynamic json) {
    if (json == null) return null;
    final map = json is String
        ? jsonDecode(json) as Map<String, dynamic>
        : json as Map<String, dynamic>;
    return MusicData.fromJson(map);
  }

  @override
  dynamic toJson(MusicData? data) => data?.toJson();
}

class MetadataConverter implements JsonConverter<Map<String, dynamic>?, dynamic> {
  const MetadataConverter();

  @override
  Map<String, dynamic>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    if (json is String && json.isNotEmpty) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  @override
  dynamic toJson(Map<String, dynamic>? data) => data;
}

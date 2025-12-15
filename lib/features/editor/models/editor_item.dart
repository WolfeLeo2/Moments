import 'package:flutter/material.dart';

/// Types of items that can be added to the editor canvas
enum EditorItemType { sticker, text, drawing }

/// Base class for all editor items (stickers, text, drawings)
class EditorItem {
  final String id;
  final EditorItemType type;
  Offset position;
  double rotation; // in radians
  double scale;
  int zIndex; // Layer order

  EditorItem({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.zIndex = 0,
  });

  EditorItem copyWith({
    Offset? position,
    double? rotation,
    double? scale,
    int? zIndex,
  }) {
    throw UnimplementedError('Subclasses must implement copyWith');
  }
}

/// A sticker item (emoji, image sticker, etc.)
class StickerItem extends EditorItem {
  final String assetPath; // Local asset or network URL
  final bool isEmoji;
  final String? emojiChar; // If isEmoji, the actual emoji character

  StickerItem({
    required super.id,
    required super.position,
    super.rotation,
    super.scale,
    super.zIndex,
    required this.assetPath,
    this.isEmoji = false,
    this.emojiChar,
  }) : super(type: EditorItemType.sticker);

  @override
  StickerItem copyWith({
    Offset? position,
    double? rotation,
    double? scale,
    int? zIndex,
    String? assetPath,
  }) {
    return StickerItem(
      id: id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      assetPath: assetPath ?? this.assetPath,
      isEmoji: isEmoji,
      emojiChar: emojiChar,
    );
  }
}

/// A text item with styling
class TextItem extends EditorItem {
  String text;
  Color textColor;
  Color? backgroundColor;
  String fontFamily;
  double fontSize;
  FontWeight fontWeight;
  TextAlign textAlign;
  bool hasOutline;
  Color outlineColor;

  TextItem({
    required super.id,
    required super.position,
    super.rotation,
    super.scale,
    super.zIndex,
    required this.text,
    this.textColor = Colors.white,
    this.backgroundColor,
    this.fontFamily = 'Bangers',
    this.fontSize = 32,
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
    this.hasOutline = true,
    this.outlineColor = Colors.black,
  }) : super(type: EditorItemType.text);

  @override
  TextItem copyWith({
    Offset? position,
    double? rotation,
    double? scale,
    int? zIndex,
    String? text,
    Color? textColor,
    Color? backgroundColor,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool? hasOutline,
    Color? outlineColor,
  }) {
    return TextItem(
      id: id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
      hasOutline: hasOutline ?? this.hasOutline,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }
}

/// A drawing path item
class DrawingItem extends EditorItem {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingItem({
    required super.id,
    required super.position,
    super.rotation,
    super.scale,
    super.zIndex,
    required this.points,
    this.color = Colors.white,
    this.strokeWidth = 5.0,
  }) : super(type: EditorItemType.drawing);

  @override
  DrawingItem copyWith({
    Offset? position,
    double? rotation,
    double? scale,
    int? zIndex,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return DrawingItem(
      id: id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

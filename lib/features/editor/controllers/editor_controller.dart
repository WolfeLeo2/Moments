import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/editor_item.dart';

/// State management for the image editor
class EditorController extends ChangeNotifier {
  final List<String> _imagePaths;
  int _currentImageIndex = 0;

  // Items for each image (keyed by image index)
  final Map<int, List<EditorItem>> _itemsPerImage = {};

  // Currently selected item
  String? _selectedItemId;

  // Current editing mode
  EditorMode _mode = EditorMode.select;

  // Drawing state
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 5.0;
  List<Offset> _currentDrawingPoints = [];

  // Text editing state
  Color _textColor = Colors.white;
  String _textFontFamily = 'Bangers';

  // Global key for capturing the canvas
  final GlobalKey canvasKey = GlobalKey();

  EditorController({required List<String> imagePaths})
    : _imagePaths = imagePaths {
    // Initialize empty item lists for each image
    for (int i = 0; i < imagePaths.length; i++) {
      _itemsPerImage[i] = [];
    }
  }

  // Getters
  List<String> get imagePaths => _imagePaths;
  int get currentImageIndex => _currentImageIndex;
  String get currentImagePath => _imagePaths[_currentImageIndex];
  List<EditorItem> get currentItems => _itemsPerImage[_currentImageIndex] ?? [];
  String? get selectedItemId => _selectedItemId;
  EditorMode get mode => _mode;
  Color get drawingColor => _drawingColor;
  double get drawingStrokeWidth => _drawingStrokeWidth;
  Color get textColor => _textColor;
  String get textFontFamily => _textFontFamily;

  EditorItem? get selectedItem {
    if (_selectedItemId == null) return null;
    try {
      return currentItems.firstWhere((item) => item.id == _selectedItemId);
    } catch (_) {
      return null;
    }
  }

  // Navigation
  void setCurrentImage(int index) {
    if (index >= 0 && index < _imagePaths.length) {
      _currentImageIndex = index;
      _selectedItemId = null;
      notifyListeners();
    }
  }

  void nextImage() {
    if (_currentImageIndex < _imagePaths.length - 1) {
      setCurrentImage(_currentImageIndex + 1);
    }
  }

  void previousImage() {
    if (_currentImageIndex > 0) {
      setCurrentImage(_currentImageIndex - 1);
    }
  }

  // Mode switching
  void setMode(EditorMode mode) {
    _mode = mode;
    if (mode != EditorMode.select) {
      _selectedItemId = null;
    }
    notifyListeners();
  }

  // Item selection
  void selectItem(String? itemId) {
    _selectedItemId = itemId;
    _mode = EditorMode.select;
    notifyListeners();
  }

  void clearSelection() {
    _selectedItemId = null;
    notifyListeners();
  }

  // Add items
  void addSticker(String assetPath, {bool isEmoji = false, String? emojiChar}) {
    final item = StickerItem(
      id: const Uuid().v4(),
      position: const Offset(150, 300), // Center-ish
      scale: isEmoji ? 1.5 : 1.0,
      assetPath: assetPath,
      isEmoji: isEmoji,
      emojiChar: emojiChar,
      zIndex: _getNextZIndex(),
    );
    _addItem(item);
    selectItem(item.id);
  }

  void addText(String text) {
    final item = TextItem(
      id: const Uuid().v4(),
      position: const Offset(150, 300),
      text: text,
      textColor: _textColor,
      fontFamily: _textFontFamily,
      zIndex: _getNextZIndex(),
    );
    _addItem(item);
    selectItem(item.id);
  }

  void _addItem(EditorItem item) {
    _itemsPerImage[_currentImageIndex]?.add(item);
    notifyListeners();
  }

  int _getNextZIndex() {
    if (currentItems.isEmpty) return 0;
    return currentItems.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b) +
        1;
  }

  // Update items
  void updateItemPosition(String itemId, Offset position) {
    final items = _itemsPerImage[_currentImageIndex];
    if (items == null) return;

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    items[index].position = position;
    notifyListeners();
  }

  void updateItemTransform(String itemId, {double? rotation, double? scale}) {
    final items = _itemsPerImage[_currentImageIndex];
    if (items == null) return;

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    if (rotation != null) items[index].rotation = rotation;
    if (scale != null) items[index].scale = scale.clamp(0.3, 5.0);
    notifyListeners();
  }

  void updateTextItem(
    String itemId, {
    String? text,
    Color? textColor,
    Color? backgroundColor,
    String? fontFamily,
    double? fontSize,
    bool? hasOutline,
  }) {
    final items = _itemsPerImage[_currentImageIndex];
    if (items == null) return;

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1 || items[index] is! TextItem) return;

    final textItem = items[index] as TextItem;
    if (text != null) textItem.text = text;
    if (textColor != null) textItem.textColor = textColor;
    if (backgroundColor != null) textItem.backgroundColor = backgroundColor;
    if (fontFamily != null) textItem.fontFamily = fontFamily;
    if (fontSize != null) textItem.fontSize = fontSize;
    if (hasOutline != null) textItem.hasOutline = hasOutline;
    notifyListeners();
  }

  // Delete items
  void deleteItem(String itemId) {
    _itemsPerImage[_currentImageIndex]?.removeWhere(
      (item) => item.id == itemId,
    );
    if (_selectedItemId == itemId) {
      _selectedItemId = null;
    }
    notifyListeners();
  }

  void deleteSelectedItem() {
    if (_selectedItemId != null) {
      deleteItem(_selectedItemId!);
    }
  }

  // Layer management
  void bringToFront(String itemId) {
    final items = _itemsPerImage[_currentImageIndex];
    if (items == null) return;

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    items[index].zIndex = _getNextZIndex();
    notifyListeners();
  }

  void sendToBack(String itemId) {
    final items = _itemsPerImage[_currentImageIndex];
    if (items == null) return;

    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final minZ = items.map((e) => e.zIndex).reduce((a, b) => a < b ? a : b);
    items[index].zIndex = minZ - 1;
    notifyListeners();
  }

  // Drawing
  void setDrawingColor(Color color) {
    _drawingColor = color;
    notifyListeners();
  }

  void setDrawingStrokeWidth(double width) {
    _drawingStrokeWidth = width;
    notifyListeners();
  }

  void startDrawing(Offset point) {
    _currentDrawingPoints = [point];
    notifyListeners();
  }

  void continueDrawing(Offset point) {
    _currentDrawingPoints.add(point);
    notifyListeners();
  }

  void endDrawing() {
    if (_currentDrawingPoints.length > 1) {
      final item = DrawingItem(
        id: const Uuid().v4(),
        position: Offset.zero,
        points: List.from(_currentDrawingPoints),
        color: _drawingColor,
        strokeWidth: _drawingStrokeWidth,
        zIndex: _getNextZIndex(),
      );
      _addItem(item);
    }
    _currentDrawingPoints = [];
    notifyListeners();
  }

  List<Offset> get currentDrawingPoints => _currentDrawingPoints;

  // Text styling
  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setTextFontFamily(String fontFamily) {
    _textFontFamily = fontFamily;
    notifyListeners();
  }

  // Export edited images
  Future<List<String>> exportEditedImages() async {
    final exportedPaths = <String>[];

    for (int i = 0; i < _imagePaths.length; i++) {
      final items = _itemsPerImage[i] ?? [];

      if (items.isEmpty) {
        // No edits, use original
        exportedPaths.add(_imagePaths[i]);
      } else {
        // Has edits - will need to render and save
        // For now, return original (rendering will be done by the canvas widget)
        exportedPaths.add(_imagePaths[i]);
      }
    }

    return exportedPaths;
  }

  // Check if any image has edits
  bool get hasEdits {
    for (final items in _itemsPerImage.values) {
      if (items.isNotEmpty) return true;
    }
    return false;
  }

  // Get items for a specific image
  List<EditorItem> getItemsForImage(int index) {
    return _itemsPerImage[index] ?? [];
  }

  // Undo/Redo could be added here
}

enum EditorMode { select, sticker, text, draw }

import 'dart:io';
import 'package:quick_actions/quick_actions.dart';

class QuickActionType {
  static const String camera = 'action_camera';
  static const String video = 'action_video';
  static const String gallery = 'action_gallery';
}

/// Service to handle home screen quick actions (long-press shortcuts)
/// Similar to Snapchat's camera shortcut
class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;
  QuickActionsService._internal();

  final QuickActions _quickActions = const QuickActions();

  // Callback to handle shortcut selection
  Function(String)? _onShortcutSelected;

  /// Initialize quick actions with shortcuts
  /// Call this after the app is initialized and user is logged in
  Future<void> initialize({
    required Function(String) onShortcutSelected,
  }) async {
    _onShortcutSelected = onShortcutSelected;

    // Set up the shortcut handler
    await _quickActions.initialize((String shortcutType) {
      _onShortcutSelected?.call(shortcutType);
    });

    // Define the shortcuts with platform-appropriate icons
    // iOS: Uses SF Symbols (system icons)
    // Android: Uses drawable resources
    await _quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'action_camera',
        localizedTitle: 'Take Photo',
        icon: Platform.isIOS ? 'camera.fill' : 'ic_camera',
      ),
      ShortcutItem(
        type: 'action_video',
        localizedTitle: 'Record Video',
        icon: Platform.isIOS ? 'video.fill' : 'ic_video',
      ),
      ShortcutItem(
        type: 'action_gallery',
        localizedTitle: 'Upload from Gallery',
        icon: Platform.isIOS ? 'photo.on.rectangle' : 'ic_gallery',
      ),
    ]);
  }

  /// Clear all quick actions (e.g., when user logs out)
  Future<void> clearShortcuts() async {
    await _quickActions.clearShortcutItems();
  }
}

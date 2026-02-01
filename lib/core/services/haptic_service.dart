import 'package:flutter/services.dart';

/// Centralized haptic feedback service for consistent tactile responses
/// All methods are static - no instantiation needed
class HapticService {
  HapticService._(); // Private constructor prevents instantiation

  /// Light tap - for subtle interactions like scrolling, selection
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap - for confirmations, button taps, card swipes
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap - for important actions like delete, errors
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for picker selections, toggle switches
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Success vibration pattern - for uploads, saves, confirmations
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error vibration pattern - for failures, validation errors
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Card snap - when carousel snaps to a new card
  static Future<void> cardSnap() async {
    await HapticFeedback.selectionClick();
  }

  /// Long press - when entering edit/delete mode
  static Future<void> longPress() async {
    await HapticFeedback.mediumImpact();
  }

  /// Photo added - when a photo is successfully added
  static Future<void> photoAdded() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
}

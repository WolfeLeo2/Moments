import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

part 'theme_provider.g.dart';

/// Key for storing theme mode in shared preferences
const _themeModeKey = 'theme_mode';

/// Theme mode notifier with persistence
/// Allows switching between light, dark, and system themes
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    // Load saved preference asynchronously
    _loadSavedTheme();
    return ThemeMode.light; // Default to light while loading
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      // Ignore errors, use default
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      // Ignore save errors
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

/// Light theme data
@riverpod
ThemeData lightTheme(Ref ref) {
  return AppTheme.lightTheme;
}

/// Dark theme data - creates dark variant of the app theme
@riverpod
ThemeData darkTheme(Ref ref) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppTheme.primaryBlue,
      secondary: AppTheme.electricPurple,
      surface: const Color(0xFF1A1A2E),
      onSurface: Colors.white,
      error: AppTheme.emergencyRed,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    cardColor: const Color(0xFF1A1A2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F1A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}

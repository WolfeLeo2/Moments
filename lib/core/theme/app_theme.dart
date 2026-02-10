import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// iOS/Cupertino-inspired theme for the Moments app.
/// Uses system-like typography (Inter), soft iOS colors, and subtle shadows.
class AppTheme {
  // ============================================
  // iOS SYSTEM COLORS
  // ============================================

  /// Primary blue - iOS system blue
  static const Color primaryBlue = CupertinoColors.systemBlue;

  /// Background - iOS system gray 6 (light mode)
  static const Color backgroundBeige = CupertinoColors.lightBackgroundGray;

  /// Card/Surface - Pure white
  static const Color cardWhite = CupertinoColors.white;

  /// Text colors
  static const Color textDark = CupertinoColors.label;
  static const Color textGray = CupertinoColors.secondaryLabel;
  static const Color textSecondary = CupertinoColors.systemGrey;

  /// Border/Separator
  static Color borderGray = const Color(0xFFD1D1D6);

  // ============================================
  // iOS ACCENT COLORS
  // ============================================
  static const Color neonPink = CupertinoColors.systemPink; // iOS Pink
  static const Color brightYellow = CupertinoColors.systemYellow; // iOS Yellow
  static const Color electricPurple = CupertinoColors.systemPurple; // iOS Purple
  static const Color vibrantGreen = CupertinoColors.systemGreen; // iOS Green
  static const Color emergencyRed = CupertinoColors.destructiveRed; // iOS Red
  static const Color tealBlue = CupertinoColors.systemTeal; // iOS Teal
  static const Color orangeAccent = CupertinoColors.activeOrange; // iOS Orange

  /// Removed - no more black borders in iOS stylea
  static const Color borderBlack = Colors.transparent;

  // ============================================
  // EMOTIONAL / MEMORY LANE COLORS (Softened for iOS)
  // ============================================
  static const Color warmCream = Color(0xFFFFFBF5);
  static const Color softIvory = Color(0xFFFFFDF8);
  static const Color coralPink = Colors.pink;
  static const Color mintGreen = Colors.green;
  static const Color skyBlue = Colors.blue;
  static const Color sunsetOrange = Colors.orangeAccent;
  static const Color lavenderPop = Colors.indigoAccent;

  // Legacy aliases
  static const Color dustyRose = coralPink;
  static const Color sageGreen = mintGreen;
  static const Color twilightBlue = skyBlue;
  static const Color amberGold = sunsetOrange;

  // ============================================
  // SPACING CONSTANTS (8dp grid system)
  // ============================================
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ============================================
  // BORDER RADIUS (iOS Style - softer, consistent)
  // ============================================
  static double radiusSmall = 10.0.r;
  static double radiusMedium = 14.0.r;
  static double radiusLarge = 20.0.r;
  static double radiusCircle = 50.0.r;
  static double radiusMomentCard = 14.0.r;

  /// iOS-style continuous corner radius for cards
  static double radiusCard = 16.0.r;

  // ============================================
  // BORDER WIDTHS (Minimal in iOS style)
  // ============================================
  static double borderThin = 0.5.w;
  static double borderMedium = 1.0.w;
  static double borderThick = 1.5.w;

  // ============================================
  // SHADOWS (iOS Style - Soft, diffused)
  // ============================================

  /// Standard card shadow - iOS-style soft elevation
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Subtle shadow for smaller elements
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Button shadow with primary color tint
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.20),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Glow effect for interactive elements
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.12),
      offset: Offset.zero,
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Elevated shadow for modals/sheets
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 16),
      blurRadius: 48,
      spreadRadius: 0,
    ),
  ];

  // Legacy alias
  static List<BoxShadow> get brutalShadow => cardShadow;
  static List<BoxShadow> get brutalShadowSmall => softShadow;

  // ============================================
  // THEME DATA
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE3F2FD),
        onPrimaryContainer: Color(0xFF001D36),
        secondary: textGray,
        onSecondary: Colors.white,
        surface: backgroundBeige,
        onSurface: textDark,
        error: emergencyRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundBeige,
      fontFamily: 'GoogleSansFlex',

      // iOS-style elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryBlue.withValues(alpha: 0.20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircle),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w600,
            
          ),
        ),
      ),

      // iOS-style card
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),

      // iOS-style app bar
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBeige.withValues(alpha: 0.94),
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.openSansCondensed(
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.4,
        ),
      ),

      // iOS-style divider
      dividerTheme: DividerThemeData(
        color: borderGray.withValues(alpha: 0.6),
        thickness: 0.5,
        space: 0,
      ),

      // iOS-style bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
        elevation: 0,
      ),
    );
  }


  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get time-of-day tint color for a moment
  static Color getTimeOfDayTint(DateTime timestamp) {
    final hour = timestamp.hour;
    if (hour >= 5 && hour < 11) {
      return amberGold.withValues(alpha: 0.03);
    } else if (hour >= 11 && hour < 17) {
      return Colors.transparent;
    } else if (hour >= 17 && hour < 21) {
      return dustyRose.withValues(alpha: 0.03);
    } else {
      return twilightBlue.withValues(alpha: 0.05);
    }
  }

  /// Get saturation multiplier based on moment age
  static double getAgeSaturation(DateTime timestamp) {
    final age = DateTime.now().difference(timestamp);
    if (age.inDays < 1) return 1.0;
    if (age.inDays < 7) return 0.95;
    if (age.inDays < 30) return 0.90;
    if (age.inDays < 365) return 0.85;
    if (age.inDays < 365 * 3) return 0.80;
    return 0.75;
  }

  /// Format timestamp as relative, emotional text
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return 'Last week';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 60) return 'Last month';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';

    final years = (diff.inDays / 365).floor();
    if (years == 1) return 'A year ago';
    if (years == 2) return 'Two years ago';
    return '$years years ago';
  }

  /// Check if moment is from same day in a previous year
  static bool isAnniversary(DateTime timestamp) {
    final now = DateTime.now();
    return timestamp.month == now.month &&
        timestamp.day == now.day &&
        timestamp.year < now.year;
  }
}

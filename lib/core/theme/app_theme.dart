import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // ============================================
  // CORE COLOR PALETTE (Playful & Bright)
  // ============================================
  static const Color primaryBlue = Color.fromARGB(
    255,
    32,
    102,
    243,
  ); // Softer Royal Blue
  static const Color backgroundBeige = Color.fromARGB(
    255,
    251,
    244,
    234,
  ); // Clean Off-White
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A); // Softer Black
  static const Color textGray = Color(0xFF718096);
  static Color borderGray = Colors.grey[200]!; // Subtle border

  // Accent Colors (Vivid & Playful)
  static const Color neonPink = Color(0xFFFF4081);
  static const Color brightYellow = Color(0xFFFFD740);
  static const Color electricPurple = Color(0xFF9C27B0);
  static const Color vibrantGreen = Color(0xFF00C853);
  static const Color emergencyRed = Color(0xFFEF5350);
  static const Color borderBlack = Colors.transparent;

  // ============================================
  // EMOTIONAL / MEMORY LANE COLORS (Playful & Bright)
  // ============================================
  static const Color warmCream = Color(0xFFFFF8E7); // Bright warm paper
  static const Color softIvory = Color(0xFFFFFDF5); // Warm card background
  static const Color coralPink = Color(0xFFFF6B6B); // Lively nostalgic pink
  static const Color mintGreen = Color(0xFF51D88A); // Fresh nature green
  static const Color skyBlue = Color(0xFF54B7F5); // Bright reflective blue
  static const Color sunsetOrange = Color(0xFFFFAA5C); // Warm sunset glow
  static const Color lavenderPop = Color(0xFFA78BFA); // Playful purple
  // Legacy aliases for emotional references
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

  // Border Radius (Soft style)
  static double radiusSmall = 12.0.r;
  static double radiusMedium = 20.0.r; // Increased roundness
  static double radiusLarge = 28.0.r; // Very round for cards
  static double radiusCircle = 50.0.r;
  static double radiusMomentCard = 16.0.r; // Rounded corners for photos

  // Border widths - Reduced or Removed
  static double borderThin = 1.0.w;
  static double borderMedium = 1.0.w;
  static double borderThick = 2.0.w;

  // Soft Shadows (diffuse blur)
  static List<BoxShadow> get brutalShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get brutalShadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get cardShadow => brutalShadow;
  static List<BoxShadow> get softShadow => brutalShadowSmall;
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Subtle glow for interactive elements
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.15),
      offset: Offset.zero,
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        surface: backgroundBeige,
        onSurface: textDark,
        secondary: textGray,
      ),
      scaffoldBackgroundColor: backgroundBeige,
      textTheme: _textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryBlue.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircle),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBeige,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      // Display styles (Bebas Neue for big headers)
      displayLarge: GoogleFonts.bebasNeue(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: 2.0,
      ),
      displayMedium: GoogleFonts.bebasNeue(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: 1.8,
      ),
      displaySmall: GoogleFonts.bebasNeue(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: 1.5,
      ),

      // Headline styles (For sticker titles)
      headlineLarge: GoogleFonts.rubik(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: textDark,
        letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.rubik(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: textDark,
        letterSpacing: 0.5,
      ),
      headlineSmall: GoogleFonts.rubik(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: textDark,
        letterSpacing: 0.5,
      ),

      // Title styles (For buttons and labels)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),

      // Body styles (For content)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textDark,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textDark,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textGray,
        height: 1.5,
      ),

      // Label styles (For small text)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textGray,
        letterSpacing: 0.5,
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
      return amberGold.withValues(alpha: 0.05); // Morning - warm amber
    } else if (hour >= 11 && hour < 17) {
      return Colors.transparent; // Afternoon - neutral
    } else if (hour >= 17 && hour < 21) {
      return dustyRose.withValues(alpha: 0.05); // Evening - dusty rose
    } else {
      return twilightBlue.withValues(alpha: 0.08); // Night - twilight blue
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
    return 0.75; // 3+ years - vintage
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

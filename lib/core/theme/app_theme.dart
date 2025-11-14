import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neubrutalism Color Palette
  static const Color primaryBlue = Color(0xFF306BFF);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color brightYellow = Color(0xFFFBFF12);
  static const Color electricPurple = Color(0xFF8338EC);
  static const Color vibrantGreen = Color(0xFF06FFA5);
  static const Color backgroundBeige = Color.fromARGB(255, 249, 240, 230);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF000000);
  static const Color textGray = Color(0xFF718096);
  static const Color borderBlack = Color(0xFF000000);

  // Spacing Constants (8dp grid system)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border Radius (Neubrutalism style)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircle = 50.0;

  // Border widths
  static const double borderThin = 2.0;
  static const double borderMedium = 2.5;
  static const double borderThick = 3.0;

  // Neubrutalism Shadows (hard shadows with no blur)
  static List<BoxShadow> get brutalShadow => [
    const BoxShadow(color: borderBlack, offset: Offset(4, 4), blurRadius: 0),
  ];

  static List<BoxShadow> get brutalShadowSmall => [
    const BoxShadow(color: borderBlack, offset: Offset(3, 3), blurRadius: 0),
  ];

  static List<BoxShadow> get cardShadow => brutalShadow;

  static List<BoxShadow> get buttonShadow => brutalShadow;

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
          shadowColor: primaryBlue.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircle),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBeige,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.bebasNeue(
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
}

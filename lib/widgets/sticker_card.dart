import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A neubrutalism-style sticker card with thick borders and shadow
class StickerCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double rotation;
  final EdgeInsets? padding;

  const StickerCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.borderWidth = 3.0,
    this.rotation = 0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// A sticker-style label/tag
class StickerLabel extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double rotation;
  final EdgeInsets padding;

  const StickerLabel({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.borderColor = Colors.black,
    this.rotation = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.rubik(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            height: 1,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Date stamp sticker (like in the reference image)
class DateStamp extends StatelessWidget {
  final int day;
  final String month;
  final Color backgroundColor;
  final double rotation;

  const DateStamp({
    super.key,
    required this.day,
    required this.month,
    this.backgroundColor = Colors.red,
    this.rotation = -0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black, width: 2.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month.toUpperCase(),
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              day.toString(),
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

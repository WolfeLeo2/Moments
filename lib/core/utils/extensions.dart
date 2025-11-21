import 'package:flutter/material.dart';

// DateTime extensions
extension DateTimeExtensions on DateTime {
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get shortDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
  }

  String get fullDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $day, $year';
  }
}

// String extensions
extension StringExtensions on String {
  String get truncated {
    if (length <= 30) return this;
    return '${substring(0, 30)}...';
  }

  String get titleCase {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

// Color extensions
extension ColorExtensions on Color {
  Color get lighten {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }

  Color get darken {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  Color withOpacityFactor(double factor) {
    return withValues(alpha: (opacity * factor).clamp(0.0, 1.0));
  }
}

// Widget extensions
extension WidgetExtensions on Widget {
  Widget get center => Center(child: this);

  Widget get expanded => Expanded(child: this);

  Widget get flexible => Flexible(child: this);

  Widget padding(EdgeInsetsGeometry padding) =>
      Padding(padding: padding, child: this);

  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget paddingSymmetric({double? horizontal, double? vertical}) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    ),
    child: this,
  );

  Widget paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    ),
    child: this,
  );

  Widget get safeArea => SafeArea(child: this);

  Widget withHero(String tag) => Hero(tag: tag, child: this);

  Widget onTap(VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: this);

  Widget fadeIn({Duration? duration, Duration? delay}) => AnimatedOpacity(
    opacity: 1.0,
    duration: duration ?? const Duration(milliseconds: 300),
    child: this,
  );

  Widget slideUp({Duration? duration, Duration? delay}) => AnimatedSlide(
    offset: Offset.zero,
    duration: duration ?? const Duration(milliseconds: 300),
    child: this,
  );
}

// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmallScreen => screenWidth < 600;

  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1024;

  bool get isLargeScreen => screenWidth >= 1024;

  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  double get statusBarHeight => MediaQuery.of(this).padding.top;

  double get bottomSafeArea => MediaQuery.of(this).padding.bottom;

  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red.shade600);
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green.shade600);
  }
}

// List extensions
extension ListExtensions<T> on List<T> {
  List<T> get removeDuplicates => toSet().toList();

  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;

  List<T> takeWhile(bool Function(T) test) {
    final result = <T>[];
    for (final item in this) {
      if (!test(item)) break;
      result.add(item);
    }
    return result;
  }
}

// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  Map<K, V> get removeNullValues {
    final result = <K, V>{};
    for (final entry in entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

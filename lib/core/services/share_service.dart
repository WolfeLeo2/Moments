import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/moment.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('ShareService');
/// Service for generating and sharing moment content.
/// Inspired by Instagram Stories, BeReal, and Locket sharing patterns.
class ShareService {
  /// Captures a widget as an image and returns the file path
  static Future<String?> captureWidgetAsImage(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/moment_share_$timestamp.png');
      await file.writeAsBytes(bytes);

      _log.d('ShareService: Image captured at ${file.path}');
      return file.path;
    } catch (e) {
      _log.e('ShareService: Failed to capture widget: $e');
      return null;
    }
  }

  /// Share a moment as an image with optional text
  static Future<void> shareImage({
    required String imagePath,
    String? text,
  }) async {
    try {
      final xFile = XFile(imagePath);
      await Share.shareXFiles([xFile], text: text);
      _log.d('ShareService: Shared image successfully');
    } catch (e) {
      _log.e('ShareService: Failed to share image: $e');
    }
  }

  /// Share just text (for quick sharing)
  static Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      _log.e('ShareService: Failed to share text: $e');
    }
  }

  /// Generate share text for a moment
  static String generateShareText(Moment moment) {
    final date = _formatDate(moment.timestamp);
    final buffer = StringBuffer();

    buffer.writeln('📍 ${moment.location}');
    buffer.writeln('📅 $date');

    if (moment.caption != null && moment.caption!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('"${moment.caption}"');
    }

    buffer.writeln();
    buffer.writeln('Shared from Moments ✨');

    return buffer.toString();
  }

  /// Generate Year in Review statistics
  static YearInReviewStats generateYearStats(List<Moment> moments, int year) {
    final yearMoments = moments.where((m) => m.timestamp.year == year).toList();

    // Count unique locations
    final uniqueLocations = <String>{};
    final locationCounts = <String, int>{};

    for (final moment in yearMoments) {
      uniqueLocations.add(moment.location);
      locationCounts[moment.location] =
          (locationCounts[moment.location] ?? 0) + 1;
    }

    // Find top location
    String? topLocation;
    int topCount = 0;
    locationCounts.forEach((location, count) {
      if (count > topCount) {
        topCount = count;
        topLocation = location;
      }
    });

    // Count by month
    final monthCounts = List.filled(12, 0);
    for (final moment in yearMoments) {
      monthCounts[moment.timestamp.month - 1]++;
    }

    // Find busiest month
    int busiestMonth = 0;
    for (int i = 1; i < 12; i++) {
      if (monthCounts[i] > monthCounts[busiestMonth]) {
        busiestMonth = i;
      }
    }

    // Count media types
    final videoCount = yearMoments.where((m) => m.mediaType == 'video').length;
    final photoCount = yearMoments.length - videoCount;

    // Calculate streak (consecutive days with moments)
    final dates =
        yearMoments
            .map(
              (m) => DateTime(
                m.timestamp.year,
                m.timestamp.month,
                m.timestamp.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    int longestStreak = 0;
    int currentStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    if (dates.isNotEmpty && longestStreak == 0) {
      longestStreak = 1;
    }

    return YearInReviewStats(
      year: year,
      totalMoments: yearMoments.length,
      uniqueLocations: uniqueLocations.length,
      topLocation: topLocation,
      topLocationCount: topCount,
      photoCount: photoCount,
      videoCount: videoCount,
      busiestMonth: busiestMonth,
      busiestMonthCount: monthCounts[busiestMonth],
      longestStreak: longestStreak,
      monthCounts: monthCounts,
      moments: yearMoments,
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}

/// Statistics for Year in Review feature
class YearInReviewStats {
  final int year;
  final int totalMoments;
  final int uniqueLocations;
  final String? topLocation;
  final int topLocationCount;
  final int photoCount;
  final int videoCount;
  final int busiestMonth;
  final int busiestMonthCount;
  final int longestStreak;
  final List<int> monthCounts;
  final List<Moment> moments;

  const YearInReviewStats({
    required this.year,
    required this.totalMoments,
    required this.uniqueLocations,
    this.topLocation,
    required this.topLocationCount,
    required this.photoCount,
    required this.videoCount,
    required this.busiestMonth,
    required this.busiestMonthCount,
    required this.longestStreak,
    required this.monthCounts,
    required this.moments,
  });
}

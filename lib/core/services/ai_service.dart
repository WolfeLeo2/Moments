import 'package:firebase_ai/firebase_ai.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('AIService');

/// Regex to strip leading/trailing quotes from AI responses
final _quotePattern = RegExp(r'^["\u0027]+|["\u0027]+$');

/// Firebase AI Logic service using the free Gemini Developer API tier.
/// Generates chapter titles, memory insights, summaries, and nostalgia nudges.
class AIService {
  AIService._();
  static final AIService _instance = AIService._();
  factory AIService() => _instance;

  GenerativeModel? _model;
  bool _initialized = false;

  /// Initialize the AI model using Gemini Developer API (free tier)
  void initialize() {
    if (_initialized) return;
    try {
      final ai = FirebaseAI.googleAI();
      _model = ai.generativeModel(model: 'gemini-2.5-flash');
      _initialized = true;
      _log.i('Firebase AI initialized (Gemini Developer API free tier)');
    } catch (e) {
      _log.e('Failed to initialize Firebase AI: $e');
    }
  }

  bool get isAvailable => _initialized && _model != null;

  String _clean(String? text) =>
      text?.trim().replaceAll(_quotePattern, '') ?? '';

  // ============================================
  // CHAPTER TITLE GENERATION
  // ============================================

  /// Generate creative chapter titles for memory groups
  Future<String?> generateChapterTitle({
    required List<Moment> moments,
    required String defaultTitle,
  }) async {
    if (!isAvailable) return null;
    try {
      final locations = moments
          .map((m) => m.location)
          .toSet()
          .take(5)
          .join(', ');
      final dateRange = _formatDateRange(moments);
      final mediaCount = moments.length;

      final prompt =
          '''
You are naming a chapter in someone's personal memory scrapbook app.
Current chapter: "$defaultTitle"
Contains $mediaCount memories from: $locations
Date range: $dateRange

Generate a creative, personal chapter title (3-6 words) that captures the feeling of these memories.
Examples: "Golden Hour Adventures", "City Lights & Late Nights", "Weekend Wanderings", "Rainy Day Magic"
Return ONLY the title text, nothing else. No quotes.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Chapter title generation failed: $e');
      return null;
    }
  }

  // ============================================
  // MEMORY INSIGHTS
  // ============================================

  /// Generate a warm insight about a collection of memories
  Future<String?> generateMemoryInsight({required List<Moment> moments}) async {
    if (!isAvailable) return null;
    try {
      final totalCount = moments.length;
      final locations = moments.map((m) => m.location).toSet();
      final locationCount = locations.length;
      final topLocations = locations.take(3).join(', ');
      final oldestDate = moments
          .map((m) => m.timestamp)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysSince = DateTime.now().difference(oldestDate).inDays;

      final prompt =
          '''
You are a warm, friendly AI in a memory journal app called "Moments".
The user has $totalCount memories across $locationCount places (including $topLocations).
Their earliest memory was $daysSince days ago.

Generate a single warm, personal sentence (max 20 words) that reflects on their memory collection.
Like something a thoughtful friend would say. No emojis, no hashtags.
Return ONLY the sentence.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Memory insight generation failed: $e');
      return null;
    }
  }

  // ============================================
  // MEMORY SUMMARY (for "Year in Review" / recap)
  // ============================================

  /// Generate a narrative summary of memories for a time period
  Future<String?> generateMemorySummary({
    required List<Moment> moments,
    required String period, // e.g., "This Week", "January 2025"
  }) async {
    if (!isAvailable) return null;
    try {
      final locations = moments
          .map((m) => m.location)
          .toSet()
          .take(8)
          .join(', ');
      final captions = moments
          .where((m) => m.caption != null && m.caption!.isNotEmpty)
          .map((m) => m.caption!)
          .take(5)
          .join('; ');

      final prompt =
          '''
You are writing a brief memory recap (2-3 sentences, max 40 words) for "$period" in a personal journal app.
Places visited: $locations
${captions.isNotEmpty ? 'Some notes the user wrote: $captions' : 'No written notes yet.'}
Total moments captured: ${moments.length}

Write warmly and personally, like reading back through a diary. No emojis or hashtags.
Return ONLY the recap text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Memory summary generation failed: $e');
      return null;
    }
  }

  // ============================================
  // NOSTALGIA NUDGES
  // ============================================

  /// Generate a gentle nudge about an old memory (for "On This Day" feature)
  Future<String?> generateNostalgiaNudge({
    required Moment moment,
    required int yearsAgo,
  }) async {
    if (!isAvailable) return null;
    try {
      final prompt =
          '''
Generate a gentle, warm notification message (max 12 words) reminding someone about a memory from $yearsAgo year${yearsAgo > 1 ? 's' : ''} ago at ${moment.location}.
${moment.caption != null ? 'They wrote: "${moment.caption}"' : ''}
This is for a "On This Day" feature in a memory app. Be warm and nostalgic.
Return ONLY the message text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Nostalgia nudge generation failed: $e');
      return null;
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  String _formatDateRange(List<Moment> moments) {
    if (moments.isEmpty) return 'unknown';
    final dates = moments.map((m) => m.timestamp).toList()..sort();
    final first = dates.first;
    final last = dates.last;
    if (first.year == last.year && first.month == last.month) {
      return '${_monthName(first.month)} ${first.year}';
    }
    return '${_monthName(first.month)} ${first.year} - ${_monthName(last.month)} ${last.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}

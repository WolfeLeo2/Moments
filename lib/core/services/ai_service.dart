import 'dart:convert';
import 'dart:typed_data';

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
  // AUTO-CAPTIONING (multimodal — image → caption)
  // ============================================

  /// Generate a caption from image bytes using multimodal input.
  /// Pass the raw bytes of the image. Returns a short, natural caption.
  Future<String?> generateCaptionFromImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (!isAvailable) return null;
    try {
      final prompt = '''
You are a creative caption writer for a personal photo memory app called "Moments".
Look at this image and write a short, natural caption (max 10 words) that
captures the mood or scene. No hashtags, no emojis. Be warm and personal,
like something you'd write in a scrapbook.
Return ONLY the caption text.
''';

      final response = await _model!.generateContent([
        Content.multi([TextPart(prompt), InlineDataPart(mimeType, imageBytes)]),
      ]);

      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Auto-captioning failed: $e');
      return null;
    }
  }

  // ============================================
  // SMART SEARCH (natural language → filter params)
  // ============================================

  /// Convert a natural language search query into structured filter parameters.
  /// Returns a JSON-like map with keys: location, dateRange, mood, people, etc.
  Future<Map<String, dynamic>?> parseSearchQuery({
    required String query,
    required List<String> availableLocations,
  }) async {
    if (!isAvailable) return null;
    try {
      final locationsStr = availableLocations.take(30).join(', ');

      final prompt =
          '''
You are a search assistant for a personal photo memory app.
The user typed: "$query"

Available locations in their library: $locationsStr

Parse this into structured filter parameters. Return ONLY valid JSON with these optional keys:
- "location": string (matched from available locations or null)
- "timeframe": string (one of: "today", "this_week", "this_month", "this_year", "last_year", or null)
- "mood": string (one of: "happy", "calm", "adventure", "cozy", "social", or null)
- "mediaType": string (one of: "photo", "video", or null)
- "keywords": list of strings (extracted meaningful words)

Return ONLY the JSON object, no explanation.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = _clean(response.text);
      if (text.isEmpty) return null;

      // Try parsing the JSON response
      try {
        final decoded = _parseJsonResponse(text);
        return decoded;
      } catch (_) {
        _log.w('Failed to parse search response as JSON');
        return null;
      }
    } catch (e) {
      _log.e('Smart search parsing failed: $e');
      return null;
    }
  }

  // ============================================
  // GROUP NARRATIVE GENERATION
  // ============================================

  /// Generate a short narrative for a group of moments (e.g., a day or event).
  /// Useful for discovery page story blocks.
  Future<String?> generateGroupNarrative({
    required List<Moment> moments,
  }) async {
    if (!isAvailable) return null;
    try {
      final locations = moments
          .map((m) => m.location)
          .toSet()
          .take(5)
          .join(', ');
      final dateRange = _formatDateRange(moments);
      final captions = moments
          .where((m) => m.caption != null && m.caption!.isNotEmpty)
          .map((m) => m.caption!)
          .take(5)
          .join('; ');

      final prompt =
          '''
You are narrating a story about a collection of ${moments.length} memories in a personal app called "Moments".
Locations: $locations
Date range: $dateRange
${captions.isNotEmpty ? 'User notes: $captions' : 'No user notes.'}

Write a short, evocative 1-2 sentence narrative (max 30 words) that brings these memories to life.
Write as if narrating a personal documentary. Warm but not sentimental. No emojis.
Return ONLY the narrative text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Group narrative generation failed: $e');
      return null;
    }
  }

  // ============================================
  // LOCATION-BASED RECOMMENDATIONS
  // ============================================

  /// Suggest a short prompt encouraging the user to revisit or explore
  /// based on their moment locations.
  Future<String?> generateLocationRecommendation({
    required List<String> visitedLocations,
    required String currentCity,
  }) async {
    if (!isAvailable) return null;
    try {
      final locStr = visitedLocations.take(10).join(', ');

      final prompt =
          '''
You are a friendly companion in a memory app called "Moments".
The user has captured memories at: $locStr
They are currently in: $currentCity

Suggest one brief, encouraging idea (max 15 words) for capturing a new moment
today — maybe revisiting a favorite spot or exploring something new nearby.
Be warm and specific when possible. No emojis. No hashtags.
Return ONLY the suggestion text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = _clean(response.text);
      return result.isNotEmpty ? result : null;
    } catch (e) {
      _log.e('Location recommendation failed: $e');
      return null;
    }
  }

  // ============================================
  // DISCOVERY FEED CURATION
  // ============================================

  /// Given a set of moments, pick out the best ones to highlight and provide
  /// a label for each highlight group. Used by the discovery page.
  Future<List<Map<String, String>>?> curateDiscoveryHighlights({
    required List<Moment> moments,
    int maxHighlights = 4,
  }) async {
    if (!isAvailable) return null;
    try {
      final momentDescriptions = moments
          .take(40)
          .map((m) {
            final loc = m.location.split(',').first.trim();
            final date =
                '${m.timestamp.day}/${m.timestamp.month}/${m.timestamp.year}';
            final caption = m.caption ?? '';
            return '- id:${m.id}, loc:"$loc", date:$date, caption:"$caption"';
          })
          .join('\n');

      final prompt =
          '''
You are curating highlights for a personal memory discovery feed in an app called "Moments".

Here are the user's recent moments:
$momentDescriptions

Pick up to $maxHighlights interesting groupings or standout moments and give each a creative short label (3-5 words).
Group by theme, location pattern, or standout individual moments.

Return ONLY a JSON array of objects with:
- "label": creative group label
- "momentIds": array of moment id strings that belong to this highlight
- "description": one-sentence warm description (max 15 words)

Return ONLY the JSON array, no explanation.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = _clean(response.text);
      if (text.isEmpty) return null;

      try {
        final decoded = _parseJsonArrayResponse(text);
        return decoded
            ?.map(
              (e) => Map<String, String>.from({
                'label': (e['label'] ?? '') as String,
                'momentIds': ((e['momentIds'] as List?)?.join(',')) ?? '',
                'description': (e['description'] ?? '') as String,
              }),
            )
            .toList();
      } catch (_) {
        _log.w('Failed to parse discovery highlights JSON');
        return null;
      }
    } catch (e) {
      _log.e('Discovery curation failed: $e');
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

  /// Parse a JSON object from potentially messy AI output.
  Map<String, dynamic>? _parseJsonResponse(String text) {
    // Strip markdown code fences if present
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }
    // Find the first { and last }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final jsonStr = cleaned.substring(start, end + 1);
    return Map<String, dynamic>.from(
      _jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  /// Parse a JSON array from potentially messy AI output.
  List<Map<String, dynamic>>? _parseJsonArrayResponse(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    final jsonStr = cleaned.substring(start, end + 1);
    final decoded = _jsonDecode(jsonStr);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return null;
  }

  dynamic _jsonDecode(String source) {
    try {
      return _jsonCodec.decode(source);
    } catch (_) {
      return null;
    }
  }

  static const _jsonCodec = JsonCodec();
}

/// Utility to detect emoji-only messages for bubble-less rendering.
///
/// WhatsApp-style rules:
/// - 1 emoji → big (48px), no bubble
/// - 2-3 emojis → medium (36px), no bubble
/// - 4+ emojis only → still no bubble but normal-ish size (28px)
/// - Mixed text + emoji → normal bubble
library;

import 'package:characters/characters.dart';

bool isEmojiOnly(String text) {
  if (text.trim().isEmpty) return false;

  // Remove all whitespace, then check if the remaining characters are all emojis.
  // This regex matches standard emoji codepoints, variation selectors,
  // ZWJ sequences, skin-tone modifiers, and flag sequences.
  final stripped = text.replaceAll(RegExp(r'\s'), '');
  // Match common emoji ranges + modifiers/ZWJ
  final emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}]' // Emoticons
    r'|[\u{1F300}-\u{1F5FF}]' // Misc Symbols and Pictographs
    r'|[\u{1F680}-\u{1F6FF}]' // Transport and Map
    r'|[\u{1F1E0}-\u{1F1FF}]' // Flags (two-letter codes)
    r'|[\u{2600}-\u{26FF}]' // Misc symbols
    r'|[\u{2700}-\u{27BF}]' // Dingbats
    r'|[\u{FE00}-\u{FE0F}]' // Variation Selectors
    r'|[\u{1F900}-\u{1F9FF}]' // Supplemental Symbols
    r'|[\u{1FA00}-\u{1FA6F}]' // Chess Symbols
    r'|[\u{1FA70}-\u{1FAFF}]' // Symbols Extended-A
    r'|[\u{200D}]' // Zero-Width Joiner (ZWJ)
    r'|[\u{20E3}]' // Combining Enclosing Keycap
    r'|[\u{FE0F}]' // Variation Selector-16
    r'|[\u{E0020}-\u{E007F}]' // Tags
    r'|[\u{231A}-\u{231B}]' // Watch, Hourglass
    r'|[\u{23E9}-\u{23F3}]' // Various symbols
    r'|[\u{23F8}-\u{23FA}]' // Various symbols
    r'|[\u{25AA}-\u{25AB}]' // Squares
    r'|[\u{25B6}]' // Play button
    r'|[\u{25C0}]' // Reverse button
    r'|[\u{25FB}-\u{25FE}]' // Squares
    r'|[\u{2934}-\u{2935}]' // Arrows
    r'|[\u{2B05}-\u{2B07}]' // Arrows
    r'|[\u{2B1B}-\u{2B1C}]' // Squares
    r'|[\u{2B50}]' // Star
    r'|[\u{2B55}]' // Circle
    r'|[\u{3030}]' // Wavy Dash
    r'|[\u{303D}]' // Part Alternation Mark
    r'|[\u{3297}]' // Circled Ideograph Congratulation
    r'|[\u{3299}]' // Circled Ideograph Secret
    r'|[\u{00A9}\u{00AE}]' // Copyright/Registered
    r'|[\u{2122}]' // TM
    r'|[\u{23CF}]' // Eject
    r'|[\u{23ED}-\u{23EF}]' // Various
    r'|[\u{2328}]' // Keyboard
    r'|[\u{1F000}-\u{1F02F}]' // Mahjong
    r'|[\u{0023}\u{002A}\u{0030}-\u{0039}]\u{FE0F}?\u{20E3}', // Keycap
    unicode: true,
  );

  final allMatches = emojiRegex.allMatches(stripped);
  final matchedLength = allMatches.fold<int>(
    0,
    (sum, m) => sum + m.end - m.start,
  );

  return matchedLength == stripped.length;
}

/// Counts the number of visible emojis (grapheme clusters that are emojis).
/// Uses Unicode grapheme cluster segmentation for accuracy.
int countEmojis(String text) {
  final stripped = text.replaceAll(RegExp(r'\s'), '');
  // Count grapheme clusters — each emoji (even ZWJ compound ones)
  // appears as one grapheme cluster.
  return stripped.characters.length;
}

/// Returns the font size for an emoji-only message.
double emojiOnlyFontSize(int emojiCount) {
  if (emojiCount == 1) return 48.0;
  if (emojiCount <= 3) return 36.0;
  return 28.0;
}

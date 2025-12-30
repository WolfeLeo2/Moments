import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moments/data/models/message.dart';

/// Simple cache service for chat list using SharedPreferences.
/// Provides instant display of conversations on app launch while fresh data loads.
class ChatListCacheService {
  static const String _cacheKey = 'cached_chat_list';
  static const String _cacheTimestampKey = 'cached_chat_list_timestamp';

  // Cache expiry: 24 hours (but we still show it, just refresh in background)
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Singleton pattern
  static final ChatListCacheService _instance =
      ChatListCacheService._internal();
  factory ChatListCacheService() => _instance;
  ChatListCacheService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save chat list to cache
  Future<void> saveChatList(List<Map<String, dynamic>> conversations) async {
    try {
      final prefs = await _preferences;

      // Convert to serializable format
      final serializable = conversations.map((conv) {
        final message = conv['lastMessage'] as Message;
        return {
          'conversationId': conv['conversationId'],
          'otherUserId': conv['otherUserId'],
          'unreadCount': conv['unreadCount'],
          'lastMessage': message.toJson(),
        };
      }).toList();

      final json = jsonEncode(serializable);
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('ChatListCache: Saved ${conversations.length} conversations');
    } catch (e) {
      debugPrint('ChatListCache: Error saving cache: $e');
    }
  }

  /// Load chat list from cache
  /// Returns null if cache is empty
  Future<List<Map<String, dynamic>>?> loadChatList() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_cacheKey);

      if (json == null) {
        debugPrint('ChatListCache: No cached data');
        return null;
      }

      final List<dynamic> decoded = jsonDecode(json);
      final conversations = decoded.map((item) {
        return {
          'conversationId': item['conversationId'] as String,
          'otherUserId': item['otherUserId'] as String,
          'unreadCount': item['unreadCount'] as int? ?? 0,
          'lastMessage': Message.fromJson(
            item['lastMessage'] as Map<String, dynamic>,
          ),
        };
      }).toList();

      debugPrint(
        'ChatListCache: Loaded ${conversations.length} conversations from cache',
      );
      return conversations;
    } catch (e) {
      debugPrint('ChatListCache: Error loading cache: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than expiry)
  Future<bool> isCacheStale() async {
    try {
      final prefs = await _preferences;
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return true;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) > _cacheExpiry;
    } catch (e) {
      return true;
    }
  }

  /// Clear the cache
  Future<void> clearCache() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('ChatListCache: Cache cleared');
    } catch (e) {
      debugPrint('ChatListCache: Error clearing cache: $e');
    }
  }
}

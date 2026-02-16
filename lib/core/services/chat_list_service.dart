import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/core/database/database.dart';

final _log = AppLogger('ChatListService');

/// Service that manages the chat list with offline-first architecture.
///
/// Responsibilities:
/// - Load cached chat list from Drift for instant UI
/// - Fetch fresh data from network and update cache
/// - Subscribe to realtime conversation changes
class ChatListService {
  final ChatRepository _chatRepo;
  final AppDatabase _db;

  ChatListService({required ChatRepository chatRepo, required AppDatabase db})
    : _chatRepo = chatRepo,
      _db = db;

  /// Stream of chat list data with cache → network → realtime updates.
  Stream<List<Map<String, dynamic>>> watchChatList() async* {
    var hasYielded = false;

    // 1. Yield cached data immediately from Drift
    final cachedEntries = await _db.loadChatList();
    if (cachedEntries.isNotEmpty) {
      final cachedData = cachedEntries
          .map((entry) {
            Message? lastMessage;
            if (entry.lastMessageJson != null) {
              try {
                lastMessage = Message.fromJson(
                  jsonDecode(entry.lastMessageJson!),
                );
              } catch (_) {}
            }
            return {
              'conversationId': entry.conversationId,
              'otherUserId': entry.otherUserId,
              'unreadCount': entry.unreadCount,
              'lastMessage': lastMessage,
            };
          })
          .where((m) => m['lastMessage'] != null)
          .toList();
      if (cachedData.isNotEmpty) {
        hasYielded = true;
        yield cachedData;
      }
    }

    // 2. Fetch fresh data and update Drift cache
    try {
      final freshData = await _chatRepo.getRecentConversations();
      if (freshData.isNotEmpty) {
        await _saveToDrift(freshData);
      }
      hasYielded = true;
      yield freshData;
    } catch (e) {
      if (!hasYielded) rethrow;
      _log.w('Network failed for chatList, using cached data', error: e);
    }

    // 3. Listen for realtime updates and save to Drift
    try {
      await for (final _ in _chatRepo.streamConversationsChanged()) {
        try {
          final updatedData = await _chatRepo.getRecentConversations();
          if (updatedData.isNotEmpty) {
            await _saveToDrift(updatedData);
          }
          yield updatedData;
        } catch (e) {
          _log.w('Error in chatList stream update', error: e);
        }
      }
    } catch (e) {
      _log.w('Realtime stream failed, staying on cached data', error: e);
    }
  }

  /// Save conversation data to Drift cache
  Future<void> _saveToDrift(List<Map<String, dynamic>> conversations) async {
    final entries = conversations.map((conv) {
      final message = conv['lastMessage'] as Message;
      return ChatListCacheCompanion.insert(
        conversationId: conv['conversationId'] as String,
        otherUserId: conv['otherUserId'] as String,
        unreadCount: Value(conv['unreadCount'] as int? ?? 0),
        lastMessageJson: Value(jsonEncode(message.toJson())),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }).toList();
    await _db.saveChatList(entries);
  }
}

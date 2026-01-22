import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/reaction.dart';

/// Message storage service for persistent local data storage (like WhatsApp)
/// Stores messages from Supabase streams to SQLite permanently
class MessageStorageService {
  static MessageStorageService? _instance;
  static Database? _database;

  MessageStorageService._();

  factory MessageStorageService() {
    _instance ??= MessageStorageService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages_cache.db');

    return await openDatabase(
      path,
      version: 3, // v3: Added reply, reactions, edited, deleted_for columns
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            content TEXT NOT NULL,
            message_type TEXT NOT NULL,
            media_url TEXT,
            metadata TEXT,
            created_at INTEGER NOT NULL,
            is_read INTEGER NOT NULL,
            is_deleted INTEGER NOT NULL,
            reply_to_message_id TEXT,
            reply_to_content TEXT,
            reply_sender_name TEXT,
            reactions TEXT,
            deleted_for TEXT,
            is_edited INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_conversation 
          ON messages(conversation_id, created_at)
        ''');

        // Table for caching conversation IDs
        await db.execute('''
          CREATE TABLE conversations (
            friend_id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrate from version 1 to 2
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS conversations (
              friend_id TEXT PRIMARY KEY,
              conversation_id TEXT NOT NULL,
              cached_at INTEGER NOT NULL
            )
          ''');
        }
        // Migrate from version 2 to 3: Add reply, reactions, edited, deleted_for columns
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE messages ADD COLUMN reply_to_message_id TEXT',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN reply_to_content TEXT',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN reply_sender_name TEXT',
          );
          await db.execute('ALTER TABLE messages ADD COLUMN reactions TEXT');
          await db.execute('ALTER TABLE messages ADD COLUMN deleted_for TEXT');
          await db.execute(
            'ALTER TABLE messages ADD COLUMN is_edited INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  /// Get stored messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ? AND is_deleted = 0',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return results.map((row) {
      // Parse metadata from JSON string
      Map<String, dynamic>? parsedMetadata;
      final rawMetadata = row['metadata'];
      if (rawMetadata != null &&
          rawMetadata is String &&
          rawMetadata.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawMetadata);
          if (decoded is Map) {
            parsedMetadata = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Ignore JSON decode errors
        }
      }

      // Parse reactions from JSON
      List<Reaction> reactions = [];
      final reactionsJson = row['reactions'] as String?;
      if (reactionsJson != null && reactionsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(reactionsJson);
          if (decoded is List) {
            reactions = decoded
                .map((e) => Reaction.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }

      // Build reply message if we have cached reply content
      Message? replyToMessage;
      final replyToContent = row['reply_to_content'] as String?;
      if (replyToContent != null && replyToContent.isNotEmpty) {
        replyToMessage = Message(
          id: row['reply_to_message_id'] as String? ?? '',
          conversationId: row['conversation_id'] as String,
          senderId: '', // We don't cache the sender ID, just the name
          content: replyToContent,
          messageType: MessageType.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        content: row['content'] as String,
        messageType: _parseMessageType(row['message_type'] as String),
        mediaUrl: row['media_url'] as String?,
        metadata: parsedMetadata,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        isRead: (row['is_read'] as int) == 1,
        isDeleted: (row['is_deleted'] as int) == 1,
        replyToMessageId: row['reply_to_message_id'] as String?,
        replyToMessage: replyToMessage,
        isEdited: (row['is_edited'] as int?) == 1,
        deletedFor: row['deleted_for'] as String?,
        reactions: reactions,
      );
    }).toList();
  }

  /// Save/update messages in persistent storage
  Future<void> saveMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      // Serialize reactions to JSON
      String? reactionsJson;
      if (message.reactions.isNotEmpty) {
        reactionsJson = jsonEncode(
          message.reactions.map((r) => r.toJson()).toList(),
        );
      }

      batch.insert('messages', {
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'content': message.content,
        'message_type': message.messageType.name,
        'media_url': message.mediaUrl,
        'metadata': message.metadata != null
            ? jsonEncode(message.metadata)
            : null,
        'created_at': message.createdAt.millisecondsSinceEpoch,
        'is_read': message.isRead ? 1 : 0,
        'is_deleted': message.isDeleted ? 1 : 0,
        'reply_to_message_id': message.replyToMessageId,
        'reply_to_content': message.replyToMessage?.content,
        'reply_sender_name': null, // Sender name comes from provider lookup
        'reactions': reactionsJson,
        'deleted_for': message.deletedFor,
        'is_edited': message.isEdited ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get last message for a conversation from local storage
  Future<Message?> getLastMessage(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ? AND is_deleted = 0',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    // Parse metadata from JSON string
    Map<String, dynamic>? parsedMetadata;
    final rawMetadata = row['metadata'];
    if (rawMetadata != null &&
        rawMetadata is String &&
        rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) {
          parsedMetadata = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Ignore JSON decode errors
      }
    }

    return Message(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String,
      content: row['content'] as String,
      messageType: _parseMessageType(row['message_type'] as String),
      mediaUrl: row['media_url'] as String?,
      metadata: parsedMetadata,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      isRead: (row['is_read'] as int) == 1,
      isDeleted: (row['is_deleted'] as int) == 1,
    );
  }

  /// Clear stored messages for a conversation
  Future<void> clearConversation(String conversationId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Clear all stored messages
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
  }

  /// Cache conversation ID for a friend
  Future<void> cacheConversationId(
    String friendId,
    String conversationId,
  ) async {
    final db = await database;
    await db.insert('conversations', {
      'friend_id': friendId,
      'conversation_id': conversationId,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get cached conversation ID for a friend
  Future<String?> getCachedConversationId(String friendId) async {
    final db = await database;
    final results = await db.query(
      'conversations',
      where: 'friend_id = ?',
      whereArgs: [friendId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first['conversation_id'] as String;
  }

  MessageType _parseMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

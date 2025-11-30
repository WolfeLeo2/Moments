import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:moments/data/models/message.dart';

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
      version: 1,
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
            is_deleted INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_conversation 
          ON messages(conversation_id, created_at)
        ''');

        // Table to cache friend_id -> conversation_id mapping
        await db.execute('''
          CREATE TABLE conversation_map (
            friend_id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL
          )
        ''');
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
      return Message(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        content: row['content'] as String,
        messageType: _parseMessageType(row['message_type'] as String),
        mediaUrl: row['media_url'] as String?,
        metadata: row['metadata'] != null
            ? Map<String, dynamic>.from(
                // Parse JSON string if needed
                row['metadata'] as Map,
              )
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        isRead: (row['is_read'] as int) == 1,
        isDeleted: (row['is_deleted'] as int) == 1,
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
      batch.insert('messages', {
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'content': message.content,
        'message_type': message.messageType.name,
        'media_url': message.mediaUrl,
        'metadata': message.metadata?.toString(),
        'created_at': message.createdAt.millisecondsSinceEpoch,
        'is_read': message.isRead ? 1 : 0,
        'is_deleted': message.isDeleted ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get cached conversation ID for a friend
  Future<String?> getConversationId(String friendId) async {
    final db = await database;
    final results = await db.query(
      'conversation_map',
      columns: ['conversation_id'],
      where: 'friend_id = ?',
      whereArgs: [friendId],
    );

    if (results.isNotEmpty) {
      return results.first['conversation_id'] as String;
    }
    return null;
  }

  /// Save conversation ID mapping
  Future<void> saveConversationId(
    String friendId,
    String conversationId,
  ) async {
    final db = await database;
    await db.insert('conversation_map', {
      'friend_id': friendId,
      'conversation_id': conversationId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    await db.delete('conversation_map');
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

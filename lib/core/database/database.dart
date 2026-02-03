import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:moments/data/models/message.dart' as app;
import 'package:moments/data/models/moment.dart' as app_moment;
import 'package:moments/data/models/profile.dart' as app_profile;
import 'package:moments/data/models/friendship.dart' as app_friendship;
import 'package:moments/data/models/pending_action.dart' as app_action;
import 'package:moments/data/models/reaction.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

part 'database.g.dart';

// ============================================
// TABLE DEFINITIONS
// ============================================

/// Messages table - stores chat messages
@DataClassName('MessageEntry')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON string
  IntColumn get createdAt => integer()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get replyToMessageId => text().nullable()();
  TextColumn get replyToContent => text().nullable()();
  TextColumn get replySenderName => text().nullable()();
  TextColumn get reactions => text().nullable()(); // JSON array
  TextColumn get deletedFor => text().nullable()();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Conversations table - caches conversation IDs for friends
@DataClassName('ConversationEntry')
class Conversations extends Table {
  TextColumn get friendId => text()();
  TextColumn get conversationId => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {friendId};
}

/// Chat list cache - stores recent conversation list for instant UI
@DataClassName('ChatListEntry')
class ChatListCache extends Table {
  TextColumn get conversationId => text()();
  TextColumn get otherUserId => text()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get lastMessageJson => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {conversationId};
}

/// Moments table - stores moment metadata
@DataClassName('MomentEntry')
class Moments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get location => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get mediaPath => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get mediaType => text().withDefault(const Constant('image'))();
  IntColumn get duration => integer().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get timestamp => integer()();
  TextColumn get userId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get momentGroupId => text().nullable()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  TextColumn get localMediaPath => text().nullable()();
  TextColumn get localThumbnailPath => text().nullable()();
  IntColumn get syncedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Media cache - tracks downloaded media files
@DataClassName('MediaCacheEntry')
class MediaCache extends Table {
  TextColumn get remotePath => text()();
  TextColumn get localPath => text()();
  IntColumn get fileSize => integer().nullable()();
  IntColumn get cachedAt => integer()();
  IntColumn get lastAccessed => integer()();

  @override
  Set<Column> get primaryKey => {remotePath};
}

/// Profiles table - caches user profiles
@DataClassName('ProfileEntry')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Friendships table - caches friendship data
@DataClassName('FriendshipEntry')
class Friendships extends Table {
  TextColumn get id => text()();
  TextColumn get userId1 => text()();
  TextColumn get userId2 => text()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending actions table - offline action queue
@DataClassName('PendingActionEntry')
class PendingActions extends Table {
  TextColumn get id => text()();
  TextColumn get actionType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// DATABASE CLASS
// ============================================

@DriftDatabase(
  tables: [
    Messages,
    Conversations,
    ChatListCache,
    Moments,
    MediaCache,
    Profiles,
    Friendships,
    PendingActions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this when schema changes
  @override
  int get schemaVersion => 2;

  // Migration strategy for future schema changes
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
      beforeOpen: (details) async {
        // Enable foreign keys if needed
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ============================================
  // MESSAGE QUERIES
  // ============================================

  /// Get messages for a conversation (newest first)
  Future<List<MessageEntry>> getMessages(String conversationId) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..where((m) => m.isDeleted.equals(false))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  /// Watch messages for a conversation (reactive stream)
  Stream<List<MessageEntry>> watchMessages(String conversationId) {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..where((m) => m.isDeleted.equals(false))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .watch();
  }

  /// Get last message for a conversation
  Future<MessageEntry?> getLastMessage(String conversationId) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..where((m) => m.isDeleted.equals(false))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Save or update messages (batch upsert)
  Future<void> saveMessages(List<MessagesCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(messages, entries);
    });
  }

  /// Clear messages for a conversation
  Future<void> clearConversation(String conversationId) async {
    await (delete(
      messages,
    )..where((m) => m.conversationId.equals(conversationId))).go();
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    await delete(messages).go();
  }

  // ============================================
  // CONVERSATION ID CACHE QUERIES
  // ============================================

  /// Get cached conversation ID for a friend
  Future<String?> getCachedConversationId(String friendId) async {
    final entry = await (select(
      conversations,
    )..where((c) => c.friendId.equals(friendId))).getSingleOrNull();
    return entry?.conversationId;
  }

  /// Cache conversation ID for a friend
  Future<void> cacheConversationId(
    String friendId,
    String conversationId,
  ) async {
    await into(conversations).insertOnConflictUpdate(
      ConversationsCompanion.insert(
        friendId: friendId,
        conversationId: conversationId,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ============================================
  // CHAT LIST CACHE QUERIES
  // ============================================

  /// Save chat list to cache
  Future<void> saveChatList(List<ChatListCacheCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(chatListCache, entries);
    });
  }

  /// Load chat list from cache (ordered by most recent)
  Future<List<ChatListEntry>> loadChatList() async {
    return (select(
      chatListCache,
    )..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])).get();
  }

  /// Clear chat list cache
  Future<void> clearChatListCache() async {
    await delete(chatListCache).go();
  }

  // ============================================
  // MOMENT QUERIES
  // ============================================

  /// Get all moments (newest first)
  Future<List<MomentEntry>> getMoments() async {
    return (select(
      moments,
    )..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();
  }

  /// Watch all moments (reactive stream)
  Stream<List<MomentEntry>> watchMoments() {
    return (select(
      moments,
    )..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).watch();
  }

  /// Get moments by user ID
  Future<List<MomentEntry>> getMomentsByUser(String userId) async {
    return (select(moments)
          ..where((m) => m.userId.equals(userId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  /// Get moment by ID
  Future<MomentEntry?> getMomentById(String momentId) async {
    return (select(
      moments,
    )..where((m) => m.id.equals(momentId))).getSingleOrNull();
  }

  /// Save moments (batch upsert)
  Future<void> saveMoments(List<MomentsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(moments, entries);
    });
  }

  /// Update moment privacy
  Future<void> updateMomentPrivacy(String momentId, bool isPrivate) async {
    await (update(moments)..where((m) => m.id.equals(momentId))).write(
      MomentsCompanion(isPrivate: Value(isPrivate)),
    );
  }

  /// Update privacy for all moments in a group
  Future<void> updateGroupPrivacy(String groupId, bool isPrivate) async {
    await (update(moments)..where((m) => m.momentGroupId.equals(groupId)))
        .write(MomentsCompanion(isPrivate: Value(isPrivate)));
  }

  /// Delete moment and associated local files
  Future<void> deleteMoment(String momentId) async {
    // Get moment to find local paths
    final moment = await (select(
      moments,
    )..where((m) => m.id.equals(momentId))).getSingleOrNull();

    if (moment != null) {
      // Delete local media files
      if (moment.localMediaPath != null) {
        try {
          await File(moment.localMediaPath!).delete();
        } catch (_) {}
      }
      if (moment.localThumbnailPath != null) {
        try {
          await File(moment.localThumbnailPath!).delete();
        } catch (_) {}
      }
    }

    // Delete from database
    await (delete(moments)..where((m) => m.id.equals(momentId))).go();
  }

  /// Clear all moments
  Future<void> clearAllMoments() async {
    await delete(moments).go();
  }

  // ============================================
  // MEDIA CACHE QUERIES
  // ============================================

  /// Get cached media path
  Future<MediaCacheEntry?> getCachedMedia(String remotePath) async {
    return (select(
      mediaCache,
    )..where((m) => m.remotePath.equals(remotePath))).getSingleOrNull();
  }

  /// Save media cache entry
  Future<void> saveMediaCache(MediaCacheCompanion entry) async {
    await into(mediaCache).insertOnConflictUpdate(entry);
  }

  /// Update last accessed time
  Future<void> updateMediaAccess(String remotePath) async {
    await (update(
      mediaCache,
    )..where((m) => m.remotePath.equals(remotePath))).write(
      MediaCacheCompanion(
        lastAccessed: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Get old media entries for cleanup
  Future<List<MediaCacheEntry>> getOldMediaEntries(int olderThanMs) async {
    return (select(
      mediaCache,
    )..where((m) => m.lastAccessed.isSmallerThanValue(olderThanMs))).get();
  }

  /// Delete media cache entry
  Future<void> deleteMediaCache(String remotePath) async {
    await (delete(
      mediaCache,
    )..where((m) => m.remotePath.equals(remotePath))).go();
  }

  // ============================================
  // PROFILE QUERIES
  // ============================================

  /// Save profiles (batch upsert)
  Future<void> saveProfiles(List<ProfilesCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(profiles, entries);
    });
  }

  /// Get all profiles
  Future<List<ProfileEntry>> getProfiles() async {
    return select(profiles).get();
  }

  /// Get profile by ID
  Future<ProfileEntry?> getProfileById(String profileId) async {
    return (select(
      profiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
  }

  /// Update a profile's avatar URL
  Future<void> updateProfileAvatarUrl(
    String profileId,
    String avatarUrl,
  ) async {
    await (update(profiles)..where((p) => p.id.equals(profileId))).write(
      ProfilesCompanion(avatarUrl: Value(avatarUrl)),
    );
  }

  // ============================================
  // FRIENDSHIP QUERIES
  // ============================================

  /// Save friendships (batch upsert)
  Future<void> saveFriendships(List<FriendshipsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(friendships, entries);
    });
  }

  /// Get all friendships
  Future<List<FriendshipEntry>> getFriendships() async {
    return select(friendships).get();
  }

  // ============================================
  // PENDING ACTION QUERIES
  // ============================================

  /// Queue a pending action
  Future<void> queuePendingAction(PendingActionsCompanion action) async {
    await into(pendingActions).insert(action);
  }

  /// Get all pending actions ordered by priority
  Future<List<PendingActionEntry>> getPendingActions() async {
    return (select(pendingActions)..orderBy([
          // High priority first
          (a) => OrderingTerm(
            expression: a.priority
                .equals('high')
                .caseMatch<int>(
                  when: {const Constant(true): const Constant(1)},
                  orElse: a.priority
                      .equals('medium')
                      .caseMatch<int>(
                        when: {const Constant(true): const Constant(2)},
                        orElse: const Constant(3),
                      ),
                ),
          ),
          // Then by creation time
          (a) => OrderingTerm.asc(a.createdAt),
        ]))
        .get();
  }

  /// Get pending action count
  Future<int> getPendingActionCount() async {
    final count = countAll();
    final query = selectOnly(pendingActions)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get actions for entity
  Future<List<PendingActionEntry>> getActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    return (select(pendingActions)..where(
          (a) => a.entityType.equals(entityType) & a.entityId.equals(entityId),
        ))
        .get();
  }

  /// Mark action as failed
  Future<void> markActionFailed(String actionId, String error) async {
    final action = await (select(
      pendingActions,
    )..where((a) => a.id.equals(actionId))).getSingleOrNull();
    if (action == null) return;

    if (action.retryCount >= 4) {
      // Max 5 retries
      await removePendingAction(actionId);
    } else {
      await (update(pendingActions)..where((a) => a.id.equals(actionId))).write(
        PendingActionsCompanion(
          retryCount: Value(action.retryCount + 1),
          lastError: Value(error),
        ),
      );
    }
  }

  /// Remove pending action
  Future<void> removePendingAction(String actionId) async {
    await (delete(pendingActions)..where((a) => a.id.equals(actionId))).go();
  }

  /// Remove actions for entity
  Future<void> removeActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    await (delete(pendingActions)..where(
          (a) => a.entityType.equals(entityType) & a.entityId.equals(entityId),
        ))
        .go();
  }

  Future<void> clearAllPendingActions() async {
    await delete(pendingActions).go();
  }

  // ============================================
  // MEDIA CACHE METHODS
  // ============================================

  /// Get media directory for caching files
  Future<Directory> get mediaDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'moment_media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get local media path for a moment
  Future<String?> getLocalMediaPath(
    String momentId, {
    bool isThumbnail = false,
  }) async {
    final results = await (select(
      moments,
    )..where((m) => m.id.equals(momentId))).getSingleOrNull();
    if (results == null) return null;

    final path = isThumbnail
        ? results.localThumbnailPath
        : results.localMediaPath;
    if (path == null) return null;

    // Verify file exists
    if (await File(path).exists()) {
      return path;
    }

    // Fallback: Check if file exists in media directory with expected filename
    try {
      final dir = await mediaDirectory;
      final filename = p.basename(path);
      final newPath = p.join(dir.path, filename);

      if (await File(newPath).exists()) {
        // Update the database with the correct path
        await (update(moments)..where((m) => m.id.equals(momentId))).write(
          MomentsCompanion(
            localMediaPath: isThumbnail ? const Value.absent() : Value(newPath),
            localThumbnailPath: isThumbnail
                ? Value(newPath)
                : const Value.absent(),
          ),
        );
        debugPrint('🔄 Updated path for moment $momentId: $newPath');
        return newPath;
      }
    } catch (e) {
      debugPrint('Error checking fallback path: $e');
    }

    return null;
  }

  /// Download and cache media for a moment
  Future<String?> cacheMedia(
    String momentId,
    String remoteUrl, {
    bool isThumbnail = false,
  }) async {
    try {
      final dir = await mediaDirectory;

      // Check if already cached
      final cached = await (select(
        mediaCache,
      )..where((m) => m.remotePath.equals(remoteUrl))).getSingleOrNull();

      if (cached != null) {
        if (await File(cached.localPath).exists()) {
          // Update last accessed
          await (update(
            mediaCache,
          )..where((m) => m.remotePath.equals(remoteUrl))).write(
            MediaCacheCompanion(
              lastAccessed: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
          return cached.localPath;
        }
      }

      // Download the file
      debugPrint(
        '⬇️ Downloading media: ${remoteUrl.substring(0, remoteUrl.length.clamp(0, 50))}...',
      );
      final response = await http.get(Uri.parse(remoteUrl));

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to download media: ${response.statusCode}');
        return null;
      }

      // Determine file extension
      String extension = '.jpg';
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('video'))
          extension = '.mp4';
        else if (contentType.contains('png'))
          extension = '.png';
        else if (contentType.contains('webp'))
          extension = '.webp';
      }

      // Save to local file
      final fileName =
          '${momentId}_${isThumbnail ? 'thumb' : 'media'}$extension';
      final localPath = p.join(dir.path, fileName);
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      // Update cache record
      await into(mediaCache).insertOnConflictUpdate(
        MediaCacheCompanion.insert(
          remotePath: remoteUrl,
          localPath: localPath,
          fileSize: Value(response.bodyBytes.length),
          cachedAt: DateTime.now().millisecondsSinceEpoch,
          lastAccessed: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Update moment's local path
      await (update(moments)..where((m) => m.id.equals(momentId))).write(
        MomentsCompanion(
          localMediaPath: isThumbnail ? const Value.absent() : Value(localPath),
          localThumbnailPath: isThumbnail
              ? Value(localPath)
              : const Value.absent(),
        ),
      );

      debugPrint(
        '✅ Cached media: $localPath (${(response.bodyBytes.length / 1024).toStringAsFixed(1)} KB)',
      );
      return localPath;
    } catch (e) {
      debugPrint('❌ Error caching media: $e');
      return null;
    }
  }
}

// ============================================
// DATABASE CONNECTION
// ============================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'moments_drift.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ============================================
// MODEL CONVERTERS
// ============================================

/// Extension to convert MessageEntry (Drift) to Message (app model)
extension MessageEntryMapper on MessageEntry {
  app.Message toModel() {
    // Parse metadata from JSON string
    Map<String, dynamic>? parsedMetadata;
    if (metadata != null && metadata!.isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata!);
        if (decoded is Map) {
          parsedMetadata = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // Parse reactions from JSON
    List<Reaction> parsedReactions = [];
    if (reactions != null && reactions!.isNotEmpty) {
      try {
        final decoded = jsonDecode(reactions!);
        if (decoded is List) {
          parsedReactions = decoded
              .map((e) => Reaction.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    // Build reply message if we have cached reply content
    app.Message? replyToMessage;
    if (replyToContent != null && replyToContent!.isNotEmpty) {
      replyToMessage = app.Message(
        id: replyToMessageId ?? '',
        conversationId: conversationId,
        senderId: '',
        content: replyToContent!,
        messageType: app.MessageType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return app.Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: app.MessageType.fromString(messageType),
      mediaUrl: mediaUrl,
      metadata: parsedMetadata,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      isRead: isRead,
      isDeleted: isDeleted,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage,
      isEdited: isEdited,
      deletedFor: deletedFor,
      reactions: parsedReactions,
    );
  }
}

/// Extension to convert Message (app model) to MessagesCompanion (Drift insert)
extension MessageToCompanion on app.Message {
  MessagesCompanion toCompanion() {
    // Serialize reactions to JSON
    String? reactionsJson;
    if (reactions.isNotEmpty) {
      reactionsJson = jsonEncode(reactions.map((r) => r.toJson()).toList());
    }

    return MessagesCompanion.insert(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: Value(messageType.name),
      mediaUrl: Value(mediaUrl),
      metadata: Value(metadata != null ? jsonEncode(metadata) : null),
      createdAt: createdAt.millisecondsSinceEpoch,
      isRead: Value(isRead),
      isDeleted: Value(isDeleted),
      replyToMessageId: Value(replyToMessageId),
      replyToContent: Value(replyToMessage?.content),
      replySenderName: const Value(null),
      reactions: Value(reactionsJson),
      deletedFor: Value(deletedFor),
      isEdited: Value(isEdited),
    );
  }
}

// ============================================
// MOMENT MODEL CONVERTERS
// ============================================

/// Extension to convert MomentEntry (Drift) to Moment (app model)
extension MomentEntryMapper on MomentEntry {
  app_moment.Moment toModel() {
    return app_moment.Moment(
      id: id,
      title: title,
      location: location,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      mediaPath: mediaPath,
      caption: caption,
      mediaType: mediaType,
      duration: duration,
      thumbnailPath: thumbnailPath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      userId: userId ?? '',
      description: description,
      momentGroupId: momentGroupId,
      isPrivate: isPrivate,
    );
  }
}

/// Extension to convert Moment (app model) to MomentsCompanion (Drift insert)
extension MomentToCompanion on app_moment.Moment {
  MomentsCompanion toCompanion() {
    return MomentsCompanion.insert(
      id: id,
      title: title,
      location: location,
      latitude: latitude,
      longitude: longitude,
      imageUrl: Value(imageUrl),
      mediaPath: Value(mediaPath),
      caption: Value(caption),
      mediaType: Value(mediaType),
      duration: Value(duration),
      thumbnailPath: Value(thumbnailPath),
      createdAt: createdAt.millisecondsSinceEpoch,
      timestamp: timestamp.millisecondsSinceEpoch,
      userId: Value(userId),
      description: Value(description),
      momentGroupId: Value(momentGroupId),
      isPrivate: Value(isPrivate),
      // Use Value.absent() to preserve existing local paths during upsert
      localMediaPath: const Value.absent(),
      localThumbnailPath: const Value.absent(),
      syncedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============================================
// PROFILE MODEL CONVERTERS
// ============================================

/// Extension to convert ProfileEntry (Drift) to Profile (app model)
extension ProfileEntryMapper on ProfileEntry {
  app_profile.Profile toModel() {
    return app_profile.Profile(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      inviteCode: inviteCode ?? '',
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
          : DateTime.now(),
      updatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : DateTime.now(),
    );
  }
}

/// Extension to convert Profile (app model) to ProfilesCompanion (Drift insert)
extension ProfileToCompanion on app_profile.Profile {
  ProfilesCompanion toCompanion() {
    return ProfilesCompanion.insert(
      id: id,
      username: Value(username),
      displayName: Value(displayName),
      avatarUrl: Value(avatarUrl),
      bio: Value(bio),
      inviteCode: Value(inviteCode),
      createdAt: Value(createdAt.millisecondsSinceEpoch),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    );
  }
}

// ============================================
// FRIENDSHIP MODEL CONVERTERS
// ============================================

/// Extension to convert FriendshipEntry (Drift) to Friendship (app model)
extension FriendshipEntryMapper on FriendshipEntry {
  app_friendship.Friendship toModel() {
    return app_friendship.Friendship(
      id: id,
      userId: userId1,
      friendId: userId2,
      status: app_friendship.FriendshipStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => app_friendship.FriendshipStatus.pending,
      ),
      requestedAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
          : DateTime.now(),
      respondedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
          : null,
    );
  }
}

/// Extension to convert Friendship (app model) to FriendshipsCompanion (Drift insert)
extension FriendshipToCompanion on app_friendship.Friendship {
  FriendshipsCompanion toCompanion() {
    return FriendshipsCompanion.insert(
      id: id,
      userId1: userId,
      userId2: friendId,
      status: status.name,
      createdAt: Value(requestedAt.millisecondsSinceEpoch),
      updatedAt: Value(respondedAt?.millisecondsSinceEpoch),
    );
  }
}

// ============================================
// PENDING ACTION MODEL CONVERTERS
// ============================================

/// Extension to convert PendingActionEntry (Drift) to PendingAction (app model)
extension PendingActionEntryMapper on PendingActionEntry {
  app_action.PendingAction toModel() {
    // Parse payload JSON
    Map<String, dynamic>? parsedPayload;
    if (payload != null && payload!.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload!);
        if (decoded is Map) {
          parsedPayload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return app_action.PendingAction(
      id: id,
      actionType: app_action.PendingActionType.values.firstWhere(
        (t) => t.name == actionType,
        orElse: () => app_action.PendingActionType.deleteMoment,
      ),
      entityType: entityType,
      entityId: entityId,
      payload: parsedPayload,
      createdAt: DateTime.parse(createdAt),
      retryCount: retryCount,
      lastError: lastError,
      priority: app_action.ActionPriority.values.firstWhere(
        (p) => p.name == priority,
        orElse: () => app_action.ActionPriority.medium,
      ),
    );
  }
}

/// Extension to convert PendingAction (app model) to PendingActionsCompanion (Drift insert)
extension PendingActionToCompanion on app_action.PendingAction {
  PendingActionsCompanion toCompanion() {
    return PendingActionsCompanion.insert(
      id: id,
      actionType: actionType.name,
      entityType: entityType,
      entityId: entityId,
      payload: Value(payload != null ? jsonEncode(payload) : null),
      createdAt: createdAt.toUtc().toIso8601String(),
      retryCount: Value(retryCount),
      lastError: Value(lastError),
      priority: Value(priority.name),
    );
  }
}

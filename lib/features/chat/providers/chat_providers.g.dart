// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the currently active chat conversation ID
/// Used to suppress notifications when the user is already viewing the chat

@ProviderFor(CurrentChatId)
const currentChatIdProvider = CurrentChatIdProvider._();

/// Tracks the currently active chat conversation ID
/// Used to suppress notifications when the user is already viewing the chat
final class CurrentChatIdProvider
    extends $NotifierProvider<CurrentChatId, String?> {
  /// Tracks the currently active chat conversation ID
  /// Used to suppress notifications when the user is already viewing the chat
  const CurrentChatIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentChatIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentChatIdHash();

  @$internal
  @override
  CurrentChatId create() => CurrentChatId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentChatIdHash() => r'db87c8beb5c262253a1797ddeda3a9f56175cf25';

/// Tracks the currently active chat conversation ID
/// Used to suppress notifications when the user is already viewing the chat

abstract class _$CurrentChatId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Message storage service provider

@ProviderFor(messageStorage)
const messageStorageProvider = MessageStorageProvider._();

/// Message storage service provider

final class MessageStorageProvider
    extends
        $FunctionalProvider<
          MessageStorageService,
          MessageStorageService,
          MessageStorageService
        >
    with $Provider<MessageStorageService> {
  /// Message storage service provider
  const MessageStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageStorageHash();

  @$internal
  @override
  $ProviderElement<MessageStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageStorageService create(Ref ref) {
    return messageStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageStorageService>(value),
    );
  }
}

String _$messageStorageHash() => r'0906386001e73e8be113ec3e352e19214bf02bcd';

/// Chat repository provider (original, simple version)

@ProviderFor(chatRepository)
const chatRepositoryProvider = ChatRepositoryProvider._();

/// Chat repository provider (original, simple version)

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// Chat repository provider (original, simple version)
  const ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'ea9e083da4dcdf131e1c2e9541b05be8efba8977';

/// Stream messages for a specific conversation with persistent storage

@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily._();

/// Stream messages for a specific conversation with persistent storage

final class MessagesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          Stream<List<Message>>
        >
    with $FutureModifier<List<Message>>, $StreamProvider<List<Message>> {
  /// Stream messages for a specific conversation with persistent storage
  const MessagesStreamProvider._({
    required MessagesStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messagesStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messagesStreamHash();

  @override
  String toString() {
    return r'messagesStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Message>> create(Ref ref) {
    final argument = this.argument as String;
    return messagesStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messagesStreamHash() => r'62232ec92e8c67479c171793f44eb8e98654e31a';

/// Stream messages for a specific conversation with persistent storage

final class MessagesStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Message>>, String> {
  const MessagesStreamFamily._()
    : super(
        retry: null,
        name: r'messagesStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream messages for a specific conversation with persistent storage

  MessagesStreamProvider call(String conversationId) =>
      MessagesStreamProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messagesStreamProvider';
}

/// Get last message for a conversation
/// First checks SQLite for instant display, then validates with Supabase
/// Uses keepAlive to prevent rebuilds when navigating away

@ProviderFor(lastMessage)
const lastMessageProvider = LastMessageFamily._();

/// Get last message for a conversation
/// First checks SQLite for instant display, then validates with Supabase
/// Uses keepAlive to prevent rebuilds when navigating away

final class LastMessageProvider
    extends
        $FunctionalProvider<AsyncValue<Message?>, Message?, FutureOr<Message?>>
    with $FutureModifier<Message?>, $FutureProvider<Message?> {
  /// Get last message for a conversation
  /// First checks SQLite for instant display, then validates with Supabase
  /// Uses keepAlive to prevent rebuilds when navigating away
  const LastMessageProvider._({
    required LastMessageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lastMessageProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lastMessageHash();

  @override
  String toString() {
    return r'lastMessageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Message?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Message?> create(Ref ref) {
    final argument = this.argument as String;
    return lastMessage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LastMessageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lastMessageHash() => r'e21e432b4db08c37e844b896ca8319ebdd8635bd';

/// Get last message for a conversation
/// First checks SQLite for instant display, then validates with Supabase
/// Uses keepAlive to prevent rebuilds when navigating away

final class LastMessageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Message?>, String> {
  const LastMessageFamily._()
    : super(
        retry: null,
        name: r'lastMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Get last message for a conversation
  /// First checks SQLite for instant display, then validates with Supabase
  /// Uses keepAlive to prevent rebuilds when navigating away

  LastMessageProvider call(String conversationId) =>
      LastMessageProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'lastMessageProvider';
}

/// Get conversation ID with a friend
/// Uses SQLite cache for instant display, validates with network in background
/// Uses keepAlive to prevent rebuilds when navigating away

@ProviderFor(conversationWithFriend)
const conversationWithFriendProvider = ConversationWithFriendFamily._();

/// Get conversation ID with a friend
/// Uses SQLite cache for instant display, validates with network in background
/// Uses keepAlive to prevent rebuilds when navigating away

final class ConversationWithFriendProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Get conversation ID with a friend
  /// Uses SQLite cache for instant display, validates with network in background
  /// Uses keepAlive to prevent rebuilds when navigating away
  const ConversationWithFriendProvider._({
    required ConversationWithFriendFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationWithFriendProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationWithFriendHash();

  @override
  String toString() {
    return r'conversationWithFriendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return conversationWithFriend(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationWithFriendProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationWithFriendHash() =>
    r'7ab54a18cd6ab4c0da8c263dc6204e3003fcb205';

/// Get conversation ID with a friend
/// Uses SQLite cache for instant display, validates with network in background
/// Uses keepAlive to prevent rebuilds when navigating away

final class ConversationWithFriendFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  const ConversationWithFriendFamily._()
    : super(
        retry: null,
        name: r'conversationWithFriendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Get conversation ID with a friend
  /// Uses SQLite cache for instant display, validates with network in background
  /// Uses keepAlive to prevent rebuilds when navigating away

  ConversationWithFriendProvider call(String friendId) =>
      ConversationWithFriendProvider._(argument: friendId, from: this);

  @override
  String toString() => r'conversationWithFriendProvider';
}

/// Get all recent messages for all conversations
/// This is optimized to fetch all at once instead of N+1 requests

@ProviderFor(recentMessages)
const recentMessagesProvider = RecentMessagesProvider._();

/// Get all recent messages for all conversations
/// This is optimized to fetch all at once instead of N+1 requests

final class RecentMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Message>>,
          Map<String, Message>,
          FutureOr<Map<String, Message>>
        >
    with
        $FutureModifier<Map<String, Message>>,
        $FutureProvider<Map<String, Message>> {
  /// Get all recent messages for all conversations
  /// This is optimized to fetch all at once instead of N+1 requests
  const RecentMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentMessagesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Message>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Message>> create(Ref ref) {
    return recentMessages(ref);
  }
}

String _$recentMessagesHash() => r'88145bbb2633907ac65f6f6fa81cd92d7363fd61';

/// Show send button state for each conversation

@ProviderFor(ShowSendButton)
const showSendButtonProvider = ShowSendButtonFamily._();

/// Show send button state for each conversation
final class ShowSendButtonProvider
    extends $NotifierProvider<ShowSendButton, bool> {
  /// Show send button state for each conversation
  const ShowSendButtonProvider._({
    required ShowSendButtonFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'showSendButtonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showSendButtonHash();

  @override
  String toString() {
    return r'showSendButtonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShowSendButton create() => ShowSendButton();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShowSendButtonProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showSendButtonHash() => r'def4fce7c6e335cffe96f55cec2b814960a0beed';

/// Show send button state for each conversation

final class ShowSendButtonFamily extends $Family
    with $ClassFamilyOverride<ShowSendButton, bool, bool, bool, String> {
  const ShowSendButtonFamily._()
    : super(
        retry: null,
        name: r'showSendButtonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Show send button state for each conversation

  ShowSendButtonProvider call(String conversationId) =>
      ShowSendButtonProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'showSendButtonProvider';
}

/// Show send button state for each conversation

abstract class _$ShowSendButton extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  bool build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Typing users state for each conversation
/// Maps user ID to timestamp of last typing event

@ProviderFor(TypingUsers)
const typingUsersProvider = TypingUsersFamily._();

/// Typing users state for each conversation
/// Maps user ID to timestamp of last typing event
final class TypingUsersProvider
    extends $NotifierProvider<TypingUsers, Map<String, DateTime>> {
  /// Typing users state for each conversation
  /// Maps user ID to timestamp of last typing event
  const TypingUsersProvider._({
    required TypingUsersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'typingUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$typingUsersHash();

  @override
  String toString() {
    return r'typingUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TypingUsers create() => TypingUsers();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, DateTime> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, DateTime>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TypingUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$typingUsersHash() => r'ef187a1f36a95aa9c8f522c9938aa183bad1a48e';

/// Typing users state for each conversation
/// Maps user ID to timestamp of last typing event

final class TypingUsersFamily extends $Family
    with
        $ClassFamilyOverride<
          TypingUsers,
          Map<String, DateTime>,
          Map<String, DateTime>,
          Map<String, DateTime>,
          String
        > {
  const TypingUsersFamily._()
    : super(
        retry: null,
        name: r'typingUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Typing users state for each conversation
  /// Maps user ID to timestamp of last typing event

  TypingUsersProvider call(String conversationId) =>
      TypingUsersProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'typingUsersProvider';
}

/// Typing users state for each conversation
/// Maps user ID to timestamp of last typing event

abstract class _$TypingUsers extends $Notifier<Map<String, DateTime>> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  Map<String, DateTime> build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<Map<String, DateTime>, Map<String, DateTime>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, DateTime>, Map<String, DateTime>>,
              Map<String, DateTime>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Recording state for each conversation

@ProviderFor(IsRecording)
const isRecordingProvider = IsRecordingFamily._();

/// Recording state for each conversation
final class IsRecordingProvider extends $NotifierProvider<IsRecording, bool> {
  /// Recording state for each conversation
  const IsRecordingProvider._({
    required IsRecordingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isRecordingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isRecordingHash();

  @override
  String toString() {
    return r'isRecordingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IsRecording create() => IsRecording();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsRecordingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isRecordingHash() => r'14a85e5e403cac361be3c9c6ae7f5c2d8afd7f8f';

/// Recording state for each conversation

final class IsRecordingFamily extends $Family
    with $ClassFamilyOverride<IsRecording, bool, bool, bool, String> {
  const IsRecordingFamily._()
    : super(
        retry: null,
        name: r'isRecordingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recording state for each conversation

  IsRecordingProvider call(String conversationId) =>
      IsRecordingProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'isRecordingProvider';
}

/// Recording state for each conversation

abstract class _$IsRecording extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  bool build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Async conversation ID provider
/// Gets or creates a conversation with a friend
/// Cached locally to persist across app restarts

@ProviderFor(conversationId)
const conversationIdProvider = ConversationIdFamily._();

/// Async conversation ID provider
/// Gets or creates a conversation with a friend
/// Cached locally to persist across app restarts

final class ConversationIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Async conversation ID provider
  /// Gets or creates a conversation with a friend
  /// Cached locally to persist across app restarts
  const ConversationIdProvider._({
    required ConversationIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationIdHash();

  @override
  String toString() {
    return r'conversationIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return conversationId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationIdHash() => r'bfbf9c3e9607439d4f1c096c43c919701c2740f2';

/// Async conversation ID provider
/// Gets or creates a conversation with a friend
/// Cached locally to persist across app restarts

final class ConversationIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  const ConversationIdFamily._()
    : super(
        retry: null,
        name: r'conversationIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Async conversation ID provider
  /// Gets or creates a conversation with a friend
  /// Cached locally to persist across app restarts

  ConversationIdProvider call(String friendId) =>
      ConversationIdProvider._(argument: friendId, from: this);

  @override
  String toString() => r'conversationIdProvider';
}

/// Get list of recent conversations with details (Realtime)

@ProviderFor(chatList)
const chatListProvider = ChatListProvider._();

/// Get list of recent conversations with details (Realtime)

final class ChatListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Get list of recent conversations with details (Realtime)
  const ChatListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatListHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return chatList(ref);
  }
}

String _$chatListHash() => r'e76301ccdd98faac27f91bca134aaa0f14c5ce1b';

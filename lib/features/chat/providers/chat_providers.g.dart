// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(lastMessage)
const lastMessageProvider = LastMessageFamily._();

/// Get last message for a conversation

final class LastMessageProvider
    extends
        $FunctionalProvider<AsyncValue<Message?>, Message?, FutureOr<Message?>>
    with $FutureModifier<Message?>, $FutureProvider<Message?> {
  /// Get last message for a conversation
  const LastMessageProvider._({
    required LastMessageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lastMessageProvider',
         isAutoDispose: true,
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

String _$lastMessageHash() => r'f0087042dc5cc41ab4982a76dcacb8e5acb8347f';

/// Get last message for a conversation

final class LastMessageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Message?>, String> {
  const LastMessageFamily._()
    : super(
        retry: null,
        name: r'lastMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get last message for a conversation

  LastMessageProvider call(String conversationId) =>
      LastMessageProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'lastMessageProvider';
}

/// Get conversation ID with a friend

@ProviderFor(conversationWithFriend)
const conversationWithFriendProvider = ConversationWithFriendFamily._();

/// Get conversation ID with a friend

final class ConversationWithFriendProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Get conversation ID with a friend
  const ConversationWithFriendProvider._({
    required ConversationWithFriendFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationWithFriendProvider',
         isAutoDispose: true,
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
    r'2827e27c2321b33933e74d867e208e29a1fbc520';

/// Get conversation ID with a friend

final class ConversationWithFriendFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  const ConversationWithFriendFamily._()
    : super(
        retry: null,
        name: r'conversationWithFriendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get conversation ID with a friend

  ConversationWithFriendProvider call(String friendId) =>
      ConversationWithFriendProvider._(argument: friendId, from: this);

  @override
  String toString() => r'conversationWithFriendProvider';
}

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

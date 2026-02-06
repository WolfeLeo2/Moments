// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_offline_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for chat offline service

@ProviderFor(chatOfflineService)
const chatOfflineServiceProvider = ChatOfflineServiceProvider._();

/// Provider for chat offline service

final class ChatOfflineServiceProvider
    extends
        $FunctionalProvider<
          ChatOfflineService,
          ChatOfflineService,
          ChatOfflineService
        >
    with $Provider<ChatOfflineService> {
  /// Provider for chat offline service
  const ChatOfflineServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatOfflineServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatOfflineServiceHash();

  @$internal
  @override
  $ProviderElement<ChatOfflineService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatOfflineService create(Ref ref) {
    return chatOfflineService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatOfflineService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatOfflineService>(value),
    );
  }
}

String _$chatOfflineServiceHash() =>
    r'bd5a286320f5e91e44037924ae2be130384225ce';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_mutation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for chat mutation service.

@ProviderFor(chatMutationService)
final chatMutationServiceProvider = ChatMutationServiceProvider._();

/// Provider for chat mutation service.

final class ChatMutationServiceProvider
    extends
        $FunctionalProvider<
          ChatMutationService,
          ChatMutationService,
          ChatMutationService
        >
    with $Provider<ChatMutationService> {
  /// Provider for chat mutation service.
  ChatMutationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMutationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMutationServiceHash();

  @$internal
  @override
  $ProviderElement<ChatMutationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatMutationService create(Ref ref) {
    return chatMutationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMutationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMutationService>(value),
    );
  }
}

String _$chatMutationServiceHash() =>
    r'5ae0ed821eaaac9617f3ec4b21c26a674261efba';

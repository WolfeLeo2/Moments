import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moments/core/services/powersync/chat_powersync_service.dart';

final chatPowerSyncServiceProvider = Provider<ChatPowerSyncService>((ref) {
  final service = ChatPowerSyncService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

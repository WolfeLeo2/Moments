import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/sources/supabase_config.dart';

part 'database_provider.g.dart';

@riverpod
class DatabaseInitializer extends _$DatabaseInitializer {
  @override
  Future<void> build() async {
    // Already initialized in main.dart, but we can verify or do extra setup here
    state = const AsyncValue.data(null);
  }
}

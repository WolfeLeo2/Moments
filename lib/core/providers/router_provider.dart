import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../router/app_router.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return AppRouter.router;
}

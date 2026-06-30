import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/navigation/presentation/widgets/app_navbar.dart';

/// Main scaffold: the StatefulShellRoute builder. Hosts the floating bottom bar
/// over the active branch. Branch state (and keep-alive) is managed natively by
/// the shell — no manual TabController/AutomaticKeepAlive needed.
class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadChatCount = ref.watch(unreadChatCountProvider).value ?? 0;

    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width * 0.70,
          offset: 20,
          borderRadius: BorderRadius.circular(500),
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(500),
          ),
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          scrollOpposite: true,
        ),
        motion: const BottomBarMotion.curved(
          duration: Duration(milliseconds: 200),
        ),
        // The active branch. The bar auto-hides via ScrollNotification bubbling.
        body: navigationShell,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AppNavbar(
            currentIndex: navigationShell.currentIndex,
            unreadChatCount: unreadChatCount,
            onDestinationSelected: (index) {
              // Tapping the active tab pops it to its initial location.
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}

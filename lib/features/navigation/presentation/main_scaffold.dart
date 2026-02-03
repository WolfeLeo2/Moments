import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/map/presentation/map_page_mapbox.dart';
import 'package:moments/features/feed/presentation/feed_page.dart';
import 'package:moments/features/chat/presentation/chat_list_page.dart';
import 'package:moments/features/map/presentation/map_page_flutter_map.dart';
/// Main scaffold with bottom navigation for the app's primary tabs
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _currentIndex;

  // Keep pages alive to preserve state
  final List<Widget> _pages = const [
    MapPage(),
    FeedPage(),
    ChatListPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final unreadChatCount = ref.watch(unreadChatCountProvider).value ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.transparent,
        height: 60,
        indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text(
                unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text(
                unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

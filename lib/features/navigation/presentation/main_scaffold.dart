import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/map/presentation/map_page_flutter_map.dart';
import 'package:moments/features/mapv2/presentation/map_page_v2.dart';
import 'package:moments/features/mapv2/providers/map_v2_providers.dart';
import 'package:moments/features/feed/presentation/memory_lane_page.dart';
import 'package:moments/features/chat/presentation/chat_list_page.dart';
import 'package:moments/features/discovery/presentation/discovery_page.dart';

/// Main scaffold with floating bottom bar navigation
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadChatCount = ref.watch(unreadChatCountProvider).value ?? 0;

    return Scaffold(
      body: BottomBar(
        borderRadius: BorderRadius.circular(500),
        duration: const Duration(milliseconds: 200),
        width: MediaQuery.of(context).size.width * 0.55,
        barColor: AppTheme.cardWhite,
        start: 2,
        end: 0,
        offset: 20,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 24,
        iconWidth: 24,
        reverse: false,
        hideOnScroll: true,
        scrollOpposite: true,

        body: (context, controller) => TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Map tab — use V2 (native Mapbox) when feature flag is on
            _KeepAlivePage(
              child: Consumer(
                builder: (context, ref, _) {
                  final useV2 = ref.watch(useMapV2Provider);
                  if (useV2) {
                    return MapPageV2(
                      scrollController: _currentIndex == 0 ? controller : null,
                    );
                  }
                  return MapPage(
                    scrollController: _currentIndex == 0 ? controller : null,
                  );
                },
              ),
            ),
            _KeepAlivePage(
              child: MemoryLanePage(
                scrollController: _currentIndex == 1 ? controller : null,
              ),
            ),
            _KeepAlivePage(
              child: DiscoveryPage(
                scrollController: _currentIndex == 2 ? controller : null,
              ),
            ),
            _KeepAlivePage(
              child: ChatListPage(
                scrollController: _currentIndex == 3 ? controller : null,
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: TabBar(
            controller: _tabController,
            indicator: UnderlineTabIndicator(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 3),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey.shade600,
            splashFactory: InkRipple.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              _buildTab(
                icon: CupertinoIcons.map,
                isSelected: _currentIndex == 0,
              ),
              _buildTab(
                icon: CupertinoIcons.rectangle_stack,
                isSelected: _currentIndex == 1,
              ),
              _buildTab(
                icon: CupertinoIcons.compass,
                isSelected: _currentIndex == 2,
              ),
              _buildTab(
                icon: CupertinoIcons.chat_bubble_2,
                isSelected: _currentIndex == 3,
                badge: unreadChatCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required bool isSelected,
    int badge = 0,
  }) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text(
              badge > 9 ? '9+' : '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.emergencyRed,
            child: Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade500,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper to keep pages alive when switching tabs
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

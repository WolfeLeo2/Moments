import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../core/services/haptic_service.dart';
import '../../discovery/presentation/discovery_page.dart';
import '../../feed/presentation/memory_lane_page.dart';

/// Combined Discover + Memory Lane page with dropdown switcher.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  int _selectedView = 0;

  static const _viewLabels = ['DISCOVER', 'Memory Lane'];

  List<PullDownMenuEntry> _buildMenuItems() {
    return List.generate(_viewLabels.length, (i) {
      return PullDownMenuItem.selectable(
        title: _viewLabels[i],
        selected: _selectedView == i,
        onTap: () {
          if (_selectedView != i) {
            HapticService.lightTap();
            setState(() => _selectedView = i);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedView,
      children: [
        DiscoveryPage(
          scrollController: _selectedView == 0 ? widget.scrollController : null,
          viewLabel: _viewLabels[_selectedView],
          pullDownMenuItems: _buildMenuItems,
        ),
        MemoryLanePage(
          scrollController: _selectedView == 1 ? widget.scrollController : null,
          viewLabel: _viewLabels[_selectedView],
          pullDownMenuItems: _buildMenuItems,
        ),
      ],
    );
  }
}

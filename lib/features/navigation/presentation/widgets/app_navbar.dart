import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';

/// Floating nav bar content: a native [TabBar] with a sliding pill indicator.
///
/// Driven by [currentIndex] (the StatefulShellRoute branch index) and reports
/// taps via [onDestinationSelected]. Keeps an internal [TabController] only to
/// animate the pill; the shell owns the actual navigation state.
class AppNavbar extends StatefulWidget {
  const AppNavbar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.unreadChatCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final int unreadChatCount;

  @override
  State<AppNavbar> createState() => _AppNavbarState();
}

class _AppNavbarState extends State<AppNavbar>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabCount = 4;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppNavbar old) {
    super.didUpdateWidget(old);
    // Keep the pill in sync when the shell changes the branch externally
    // (deep link, notification tap, back gesture).
    if (widget.currentIndex != _tab.index) {
      _tab.animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 60,
      child: TabBar(
        controller: _tab,
        onTap: widget.onDestinationSelected,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        // The sliding pill.
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        indicator: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        tabs: [
          _NavTab(
            icon: CupertinoIcons.map,
            label: 'Map',
            selected: widget.currentIndex == 0,
          ),
          _NavTab(
            icon: CupertinoIcons.rectangle_stack,
            label: 'Spotlight',
            selected: widget.currentIndex == 1,
          ),
          _NavTab(
            icon: CupertinoIcons.compass,
            label: 'Explore',
            selected: widget.currentIndex == 2,
          ),
          _NavTab(
            icon: CupertinoIcons.chat_bubble_2,
            label: 'Chats',
            selected: widget.currentIndex == 3,
            badge: widget.unreadChatCount,
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryBlue : Colors.grey.shade500;

    return Tab(
      height: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text(badge > 9 ? '9+' : '$badge'),
            backgroundColor: AppTheme.emergencyRed,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

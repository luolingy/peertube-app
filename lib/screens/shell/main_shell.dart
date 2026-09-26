import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/notifications_controller.dart';

/// Application shell holding the primary navigation.
///
/// Uses a bottom navigation bar on narrow layouts and a navigation rail on
/// wide ones (desktop/web), which is what a video site needs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;

  /// Current location, used to highlight the active destination.
  final String location;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(Routes.home, '首页', Icons.home_outlined, Icons.home_rounded),
    _Destination(Routes.browse, '发现', Icons.explore_outlined, Icons.explore_rounded),
    _Destination(Routes.search, '搜索', Icons.search_outlined, Icons.search_rounded),
    _Destination(Routes.library, '我的', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  int _indexFor(String location) {
    if (location.startsWith(Routes.browse)) return 1;
    if (location.startsWith(Routes.search)) return 2;
    if (location.startsWith(Routes.library)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(location);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 960;
    final unread = context.watch<NotificationsController>().unreadCount;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (int value) =>
                  context.go(_destinations[value].route),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map(
                    (_Destination destination) => NavigationRailDestination(
                      icon: _badged(destination.icon, unread, destination.route),
                      selectedIcon: _badged(destination.selectedIcon, unread, destination.route),
                      label: Text(destination.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) => context.go(_destinations[value].route),
        destinations: _destinations
            .map(
              (_Destination destination) => NavigationDestination(
                icon: _badged(destination.icon, unread, destination.route),
                selectedIcon: _badged(destination.selectedIcon, unread, destination.route),
                label: destination.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _badged(IconData icon, int unread, String route) {
    if (unread <= 0 || route != Routes.library) return Icon(icon);
    return Badge.count(
      count: unread,
      child: Icon(icon),
    );
  }
}

class _Destination {
  const _Destination(this.route, this.label, this.icon, this.selectedIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

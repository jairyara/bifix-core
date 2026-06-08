import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// App shell with a bottom navigation bar across the four main sections.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (route: Routes.home, icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: 'Inicio'),
    (route: Routes.rides, icon: Icons.route_outlined, selected: Icons.route, label: 'Recorridos'),
    (route: Routes.maintenance, icon: Icons.build_outlined, selected: Icons.build, label: 'Mantenimiento'),
    (route: Routes.profile, icon: Icons.person_outline, selected: Icons.person, label: 'Perfil'),
  ];

  int _indexFor(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => loc == t.route);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selected),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

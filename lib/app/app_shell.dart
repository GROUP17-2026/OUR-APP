import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/animated_bottom_nav.dart';
import '../core/widgets/mesh_gradient_background.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static final destinations = <NavDestination>[
    (path: '/home', icon: Icons.home_rounded, label: 'Home'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: child),
        extendBody: true,
        bottomNavigationBar: AnimatedBottomNav(
          currentPath: location,
          destinations: destinations,
        ),
      ),
    );
  }
}

/// Shell with explicit [location] when routing state is not available.
class AppShellLocation extends StatelessWidget {
  const AppShellLocation({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: child),
        extendBody: true,
        bottomNavigationBar: AnimatedBottomNav(
          currentPath: location,
          destinations: AppShell.destinations,
        ),
      ),
    );
  }
}

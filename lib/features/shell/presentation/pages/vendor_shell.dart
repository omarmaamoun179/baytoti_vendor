import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/vendor_nav_bar.dart';

/// The tab chrome the family's everyday screens live inside.
///
/// [StatefulShellRoute.indexedStack] gives each branch its own [Navigator],
/// so a tab keeps its scroll position and stack when you switch away and
/// back. Screens pushed from a tab — an order, the product form, the
/// notifications — go over the whole shell, bar included.
class VendorShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const VendorShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: VendorNavBar(
        currentIndex: navigationShell.currentIndex,
        // Tapping the tab you are already on pops that branch to its root.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../di/di_exports.dart';

/// A widget that manages app lifecycle and performs actions when the app
/// is resumed from background.
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconcile connectivity state after the user may have toggled airplane
      // mode or switched networks while the app was backgrounded.
      if (sl.isRegistered<NetworkCubit>()) {
        sl<NetworkCubit>().checkConnection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

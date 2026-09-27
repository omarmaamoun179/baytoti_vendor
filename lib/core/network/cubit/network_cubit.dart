import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../abstract/base_cubit.dart';
import '../network_info.dart';
import 'network_state.dart';

/// Monitors real internet reachability and exposes the current status as
/// Cubit states.
///
/// Listens to [NetworkInfo.onStatusChange] and emits [NetworkConnected] or
/// [NetworkDisconnected] accordingly. The [StreamSubscription] is cancelled
/// in [close] to prevent memory leaks.
class NetworkCubit extends BaseCubit<NetworkState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<InternetStatus>? _subscription;

  NetworkCubit(this._networkInfo) : super(const NetworkInitial()) {
    _monitorConnection();
  }

  void _monitorConnection() {
    _subscription = _networkInfo.onStatusChange.listen((status) {
      switch (status) {
        case InternetStatus.connected:
          emit(const NetworkConnected());
        case InternetStatus.disconnected:
          emit(const NetworkDisconnected());
      }
    });
  }

  /// Performs an on-demand connectivity check.
  ///
  /// If internet is available, emits [NetworkConnected] so that any
  /// UI listener (e.g. [ConnectivityWrapper]) can react immediately
  /// instead of waiting for the next periodic stream event.
  Future<bool> checkConnection() async {
    final hasAccess = await _networkInfo.hasInternetAccess;
    if (hasAccess) {
      emit(const NetworkConnected());
    }
    return hasAccess;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

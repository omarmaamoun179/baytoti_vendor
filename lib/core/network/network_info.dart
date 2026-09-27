import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Abstract contract for checking actual internet reachability.
///
/// Injected into Repositories so they can decide whether to call a
/// remote data source or return a cached/failure result.
abstract class NetworkInfo {
  /// Returns `true` when the device can actually reach the internet
  /// (not just whether a network interface is up).
  Future<bool> get hasInternetAccess;

  /// Continuous stream of [InternetStatus] changes.
  Stream<InternetStatus> get onStatusChange;
}

/// Concrete implementation backed by [InternetConnection] from
/// `internet_connection_checker_plus`.
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connection;

  NetworkInfoImpl(this._connection);

  @override
  Future<bool> get hasInternetAccess => _connection.hasInternetAccess;

  @override
  Stream<InternetStatus> get onStatusChange => _connection.onStatusChange;
}

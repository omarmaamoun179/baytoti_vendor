import 'dart:developer' as developer;

/// Logs a caught error beside the operation that caught it.
///
/// [reason] names the method — `OrdersRemoteDataSource.getOrders` — so a log
/// line points at the call that failed rather than at this helper. Every
/// catch in the app logs through here before it returns.
void logError(Object error, StackTrace stackTrace, {required String reason}) {
  developer.log(
    reason,
    name: 'error',
    error: error,
    stackTrace: stackTrace,
  );
}

/// Base for every error this app throws deliberately.
///
/// Data sources throw these; repositories catch them and convert to
/// `Either<Failure, T>` so nothing below the domain layer ever sees an
/// exception type.
sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The device could not reach the server — no network, DNS failure, TLS
/// handshake problem, or a request that timed out.
///
/// Distinct from [RequestException] because it is the only failure worth
/// retrying unchanged, and the only one that should offer a cached read.
class ConnectionException extends AppException {
  const ConnectionException([super.message = 'connection_error']);
}

/// The server answered, but with an error the caller has to handle —
/// validation, an expired session, a 5xx.
class RequestException extends AppException {
  /// Backend error code (`st_0004`), when the body carries one.
  final String? code;

  final int? statusCode;

  /// Field-level validation errors, keyed by field name.
  final Map<String, dynamic>? errors;

  const RequestException(
    super.message, {
    this.code,
    this.statusCode,
    this.errors,
  });
}

/// An identical request is already in flight.
///
/// Thrown rather than silently joining the pending call: a duplicate almost
/// always means a double tap or a rebuild loop, and swallowing it hides the
/// bug while still costing the round trip.
class RedundantRequestException extends AppException {
  const RedundantRequestException(super.message);
}

/// The server refused the token a call was sent with, so the session that
/// call belonged to is over — Sanctum tokens cannot be renewed. The network
/// layer has already dropped the token by the time this is thrown.
class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'session_expired']);
}

/// Local storage could not be read or written.
///
/// Declared so `mapExceptionToFailure` has a case to answer with
/// [CacheFailure]; no data source throws it yet.
class CacheException extends AppException {
  const CacheException([super.message = 'cache_error']);
}

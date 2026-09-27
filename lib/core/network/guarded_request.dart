import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';

import '../domain/failure.dart';
import '../domain/failure_mapper.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/app_logger.dart';

/// The try/catch every data-source method runs inside.
///
/// Data sources are the only layer that catches, so a method's whole body is
/// `guardedRequest('XDataSource.method', () async { … })` and it returns
/// `Either<Failure, T>` — nothing escapes as an exception. Two paths, never
/// merged:
///
///  * an [AppException] — the transport or the server reported a failure —
///    becomes its typed [Failure] through [mapExceptionToFailure];
///  * anything else — a cast, a missing key, a body that did not parse — is
///    an [UnexpectedFailure]. Calling it a connection error would tell someone
///    with a working network to go and check it.
///
/// Model parsing belongs inside [call], so a bad payload takes the second
/// path instead of escaping.
///
/// [fallbackMessage] is a translation key naming the operation, used when a
/// failure has nothing better to say. [messageForStatus] renames one status
/// for this call only — `{404: 'order_not_found'}` — and the result is still
/// a `Left`.
Future<Either<Failure, T>> guardedRequest<T>(
  String reason,
  Future<T> Function() call, {
  String fallbackMessage = 'unexpected_error',
  Map<int, String> messageForStatus = const {},
}) async {
  try {
    return Right(await call());
  } on AppException catch (e, s) {
    logError(e, s, reason: reason);
    return Left(mapExceptionToFailure(
      _renamed(e, messageForStatus),
      fallbackMessage: fallbackMessage,
    ));
  } catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: fallbackMessage.tr()));
  }
}

/// The storage twin of [guardedRequest], for local data sources.
///
/// A platform failure reading or writing the Keychain/Keystore is a
/// [CacheFailure]. A stored value that no longer parses — written by an older
/// build — is an [UnexpectedFailure], for the same reason a malformed
/// response is: the storage worked, the data did not.
///
/// [fallbackMessage] names the operation for a storage failure — the default
/// speaks of reading, which is wrong for a write.
Future<Either<Failure, T>> guardedStorage<T>(
  String reason,
  Future<T> Function() call, {
  String fallbackMessage = 'cache_error',
}) async {
  try {
    return Right(await call());
  } on FormatException catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: 'unexpected_error'.tr()));
  } on TypeError catch (e, s) {
    logError(e, s, reason: reason);
    return Left(UnexpectedFailure(message: 'unexpected_error'.tr()));
  } catch (e, s) {
    logError(e, s, reason: reason);
    return Left(CacheFailure(message: fallbackMessage.tr()));
  }
}

/// The exception with its message swapped for [renames]'s entry, when its
/// status has one. Field errors are kept: a renamed 422 is still a form to
/// fix.
AppException _renamed(AppException e, Map<int, String> renames) {
  if (e is! RequestException) return e;

  final message = renames[e.statusCode];
  if (message == null) return e;

  return RequestException(
    message,
    code: e.code,
    statusCode: e.statusCode,
    errors: e.errors,
  );
}

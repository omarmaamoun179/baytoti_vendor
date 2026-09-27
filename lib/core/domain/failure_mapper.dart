import 'package:easy_localization/easy_localization.dart';

import '../exceptions/app_exceptions.dart';
import 'failure.dart';

/// Turns anything thrown below the domain into a typed [Failure].
///
/// The network layer throws raw exceptions, not failures: a
/// [ConnectionException] when the device cannot reach the server and a
/// [RequestException] for a server-side rejection. Every data source's catch
/// funnels through here (by way of `guardedRequest`), so the
/// offline-vs-server decision is made once instead of being re-derived — and
/// lost — in each feature.
///
/// Anything that is not an [AppException] is an [UnexpectedFailure]: a parse
/// or type error is neither the network nor the server refusing.
///
/// It is also the boundary where a message becomes safe to display. Below
/// this line a message may be a translation key (`order_not_found`), the
/// API's own prose ("These credentials do not match our records."), or
/// developer text (a pending request's URL). Above it, [Failure.message] is
/// always something a toast can show.
///
/// [fallbackMessage] is used only for an error this does not recognise and
/// should be a translation key naming the operation that failed.
Failure mapExceptionToFailure(
  Object error, {
  String fallbackMessage = 'unexpected_error',
}) {
  if (error is Failure) return error;

  return switch (error) {
    // The sentinel on a transport failure (`connection_error`) is not a
    // translation key and never was one, so it is dropped for the message
    // that actually describes being offline.
    ConnectionException() => NetworkFailure(message: 'connection_failed'.tr()),

    SessionExpiredException() => ServerFailure(
        message: 'session_expired'.tr(),
        statusCode: 401,
      ),

    CacheException() => CacheFailure(
        message: _display(error.message, 'cache_error'),
      ),

    // Its message is the URL of a request already in flight. A double tap is
    // a bug to fix, not news for the user, so only the generic line escapes.
    RedundantRequestException() => ServerFailure(message: fallbackMessage.tr()),

    // A 422 is the only failure carrying per-field detail, and the only one
    // allowed to arrive without a summary message.
    RequestException(:final errors?) when errors.isNotEmpty =>
      ValidationFailure(
        message: _displayOrNull(error.message),
        statusCode: error.statusCode ?? 422,
        fieldErrors: flattenFieldErrors(errors),
      ),

    RequestException() => ServerFailure(
        message: _display(error.message, 'server_error'),
        statusCode: error.statusCode,
      ),

    // [AppException] is sealed and every variant is named above, so there is
    // no arm for the base type — adding one here would be dead code. A new
    // variant lands on the default below, so add its case when you add it.
    _ => UnexpectedFailure(message: fallbackMessage.tr()),
  };
}

/// `{"email": ["taken", "…"]}` → `{"email": "taken"}`.
///
/// Keys keep the API's dot notation (`colors.0.color_id`) so a caller can
/// match them against nested form fields.
Map<String, String> flattenFieldErrors(Map<String, dynamic>? errors) {
  if (errors == null) return const {};

  return {
    for (final entry in errors.entries)
      entry.key: switch (entry.value) {
        final List<dynamic> list when list.isNotEmpty => '${list.first}',
        final List<dynamic> _ => '',
        final Object? value => '$value',
      },
  };
}

/// Resolves a message for display, falling back to [fallbackKey] when there
/// is nothing to resolve.
///
/// `.tr()` is safe on either kind of input: a real key resolves to its
/// translation, and the API's prose is not a key so it comes back untouched.
/// That is also why a missing key is a visible bug rather than a crash —
/// `easy_localization` returns the key itself — and why every sentinel the
/// app throws has an entry in `assets/translations`.
String _display(String message, String fallbackKey) =>
    message.trim().isEmpty ? fallbackKey.tr() : message.tr();

/// As [_display], but keeps "the server said nothing" as null rather than
/// inventing a line — a 422's field errors are the message in that case.
String? _displayOrNull(String message) =>
    message.trim().isEmpty ? null : message.tr();

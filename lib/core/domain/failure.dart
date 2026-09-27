import 'package:equatable/equatable.dart';

/// What a data source hands the layers above in place of an exception.
///
/// The subtype is the point. A cubit has to tell **offline**
/// ([NetworkFailure]) from a **server rejection** ([ServerFailure]) to choose
/// between "check your connection and try again" and "this request was
/// refused" — a distinction that is lost the moment every catch arm produces
/// the same shapeless failure.
///
/// Sealed, so a `switch` over a failure is exhaustive and adding a case here
/// makes the compiler point at every screen that has to decide what it means.
/// Built inside a data source's catch — through `guardedRequest`, which hands
/// the network layer's exception types to `mapExceptionToFailure` and
/// everything else to [UnexpectedFailure].
sealed class Failure extends Equatable {
  const Failure({this.message, this.statusCode});

  /// Ready to show. Resolved through `.tr()` where the failure is built, so a
  /// screen can put it straight in a toast — the exception messages
  /// underneath are translation keys and are not safe to display raw.
  ///
  /// Null when there is nothing worth repeating, which a 422 that sent only
  /// `errors` really is; see `AuthState.displayError` for the fallback.
  final String? message;

  /// The HTTP status behind the failure, when there was a response at all.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The device could not reach the server — no network, DNS, TLS, or a
/// timeout.
///
/// The one failure worth retrying unchanged, and the only one that should
/// offer a cached read instead of an error.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message, super.statusCode});
}

/// The server answered and refused, or something unrecognised went wrong.
class ServerFailure extends Failure {
  const ServerFailure({super.message, super.statusCode});
}

/// Local storage could not be read or written.
///
/// Nothing throws the `CacheException` this maps from yet — the local data
/// sources let storage errors surface as plain exceptions — so this is here
/// for the layer to grow into rather than in use today.
class CacheFailure extends Failure {
  const CacheFailure({super.message, super.statusCode});
}

/// Something broke that was neither the network nor the server — a response
/// that did not parse, a type the model did not expect, a null where a value
/// was promised.
///
/// Kept apart from [NetworkFailure] so a parsing bug never tells someone to
/// check a connection that works, and apart from [ServerFailure] so it never
/// reads as the server refusing. Not worth retrying unchanged.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message, super.statusCode});
}

/// A 422 with per-field detail attached.
///
/// The API's guide is explicit that validation messages must be read from
/// `errors` and mapped onto inputs, not flattened into a single banner — so
/// the failure that reaches a cubit carries them rather than dropping them at
/// the repository boundary.
///
/// Keys keep the API's dot notation (`colors.0.color_id`), which is what a
/// nested form needs to match them.
class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    super.message,
    super.statusCode = 422,
    this.fieldErrors = const {},
  });

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  /// The message for [field], or null when the API did not flag it.
  String? operator [](String field) => fieldErrors[field];

  @override
  List<Object?> get props => [...super.props, fieldErrors];

  @override
  String toString() => '$runtimeType($statusCode): $message $fieldErrors';
}

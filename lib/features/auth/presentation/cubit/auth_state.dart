import 'package:equatable/equatable.dart';

import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/vendor_user.dart';

enum AuthStatus {
  /// Nothing has been checked yet.
  initial,

  /// Restoring, sending a code, checking one, or signing out.
  loading,

  /// A code is out and the OTP screen is waiting on it:
  /// [AuthState.challenge] is set.
  codeSent,

  /// Signed in. [AuthState.user] is set.
  authenticated,

  /// Checked, and nobody is signed in.
  unauthenticated,

  /// The last attempt failed. [AuthState.challenge] is kept, so a wrong code
  /// leaves the vendor on the code screen rather than back at the start.
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final VendorUser? user;

  /// The code the server is waiting on, while signing in.
  final OtpChallenge? challenge;

  final String? errorMessage;

  /// Per-field messages from a 422, keyed by the API's field names.
  final Map<String, String> fieldErrors;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.challenge,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isLoading => status == AuthStatus.loading;

  bool get hasSession => user != null && status == AuthStatus.authenticated;

  /// What to show for a failed attempt. Every field error is listed, one per
  /// line, rather than the API's summary of the first.
  String? get displayError {
    final messages = [
      for (final message in fieldErrors.values)
        if (message.trim().isNotEmpty) message,
    ];
    return messages.isNotEmpty ? messages.join('\n') : errorMessage;
  }

  /// [errorMessage] and [fieldErrors] are cleared on every copy unless passed
  /// again — an error belongs to one attempt. [challenge] is carried: a
  /// failed resend must not lose the code it was retrying.
  AuthState copyWith({
    AuthStatus? status,
    VendorUser? user,
    OtpChallenge? challenge,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      challenge: challenge ?? this.challenge,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  /// Signed in: the code is spent, which [copyWith] cannot express.
  AuthState signedIn(VendorUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  /// Signed out: the account gone, which [copyWith] cannot express.
  AuthState signedOut({String? errorMessage}) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, user, challenge, errorMessage, fieldErrors];
}

import 'package:equatable/equatable.dart';

import 'auth_params.dart';

/// A code the server has sent and is waiting on — the answer to
/// `/auth/request-otp` and `/auth/resend-otp`.
class OtpChallenge extends Equatable {
  /// What `/auth/verify-otp` sends back with the code.
  final String requestId;

  /// Where the code went, E.164.
  final String phone;

  final AuthMode mode;

  /// How many digits the code has; the boxes follow it.
  final int digits;

  final Duration expiresIn;

  /// How long before another code may be asked for.
  final Duration resendAfter;

  /// The code itself, from fixtures only, so a demo can get past the
  /// screen. The live API never sends it.
  final String? demoCode;

  const OtpChallenge({
    required this.requestId,
    required this.phone,
    required this.mode,
    this.digits = 4,
    this.expiresIn = const Duration(minutes: 2),
    this.resendAfter = const Duration(seconds: 30),
    this.demoCode,
  });

  @override
  List<Object?> get props =>
      [requestId, phone, mode, digits, expiresIn, resendAfter, demoCode];
}

import 'package:equatable/equatable.dart';

import 'auth_params.dart';

/// A code the server has sent and is waiting on — the answer to
/// `POST /auth/request-otp`, which says nothing but that it went out.
///
/// The API names no request: `/auth/verify-otp` checks the code against the
/// number, so [phone] is what the code screen sends back.
class OtpChallenge extends Equatable {
  /// Digits in a live code. Lives on the domain so the boxes on screen and
  /// what the endpoint accepts cannot drift apart.
  static const int codeLength = 6;

  /// Where the code went, E.164.
  final String phone;

  final AuthMode mode;

  /// How many digits the code has; the boxes follow it.
  final int digits;

  final Duration expiresIn;

  /// How long before another code may be asked for.
  final Duration resendAfter;

  /// The code itself, when the server hands it over — the fixtures always,
  /// and the live API while its SMS is stubbed (the code rides in the
  /// request's message). Shown under the boxes so a test can get past them.
  final String? demoCode;

  const OtpChallenge({
    required this.phone,
    required this.mode,
    this.digits = codeLength,
    this.expiresIn = const Duration(minutes: 3),
    this.resendAfter = const Duration(seconds: 60),
    this.demoCode,
  });

  @override
  List<Object?> get props =>
      [phone, mode, digits, expiresIn, resendAfter, demoCode];
}

import 'package:equatable/equatable.dart';

/// The two tabs of the sign-in screen. Both end in a code sent to the phone;
/// [signup] first creates the account (`POST /auth/vendor/register`).
enum AuthMode { login, signup }

/// How a number the app sent is shown back — the code screen's "we sent a
/// code to …". The phone field (`PhoneTextFormField`) picks the country and
/// reports E.164; this only groups a Kuwaiti number the way the design
/// prints one, and shows any other exactly as it went out.
class KuwaitPhone {
  KuwaitPhone._();

  static const String dialCode = '+965';
  static const int localLength = 8;

  /// `+96551502244` → `+965 5150 2244`; anything else unchanged.
  static String display(String e164) {
    if (!e164.startsWith(dialCode)) return e164;
    final local = e164.substring(dialCode.length);
    if (local.length != localLength) return e164;
    return '$dialCode ${local.substring(0, 4)} ${local.substring(4)}';
  }
}

/// Limits on the family name a new account is created with — inside the
/// API's `name` (3–100), `business_name` and `store_name` (3–255), all three
/// of which it fills.
class FamilyName {
  FamilyName._();

  static const int minLength = 3;
  static const int maxLength = 60;
}

/// What the sign-up tab adds to the number: the rest of the
/// `VendorRegisterRequest` the API requires.
///
/// The family is the business and its first store, so [familyName] goes out
/// as the account's `name`, `business_name` and `store_name` alike; the store
/// tab renames the store later.
class SignupDetails extends Equatable {
  static const int emailMaxLength = 255;

  /// The API's `password` minimum; the form's strength rule is stricter.
  static const int passwordMinLength = 8;

  final String familyName;
  final String email;
  final String password;
  final String passwordConfirmation;

  const SignupDetails({
    required this.familyName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [familyName, email, password, passwordConfirmation];

  @override
  String toString() => 'SignupDetails($familyName, $email, password: ***)';
}

class RequestOtpParams extends Equatable {
  /// E.164, as the phone field reports it (`+96551502244`). The API takes
  /// the digits alone.
  final String phone;

  final AuthMode mode;

  /// Required for [AuthMode.signup]; ignored for a sign-in.
  final SignupDetails? signup;

  const RequestOtpParams({
    required this.phone,
    required this.mode,
    this.signup,
  });

  @override
  List<Object?> get props => [phone, mode, signup];
}

/// A code and the number it was sent to — the body of
/// `POST /auth/verify-otp`.
class VerifyOtpParams extends Equatable {
  /// E.164, as the challenge holds it.
  final String phone;

  /// Sent as a string: a leading zero must survive the trip.
  final String code;

  /// Which tab sent the code — a sign-up opens a new family's session.
  final AuthMode mode;

  const VerifyOtpParams({
    required this.phone,
    required this.code,
    required this.mode,
  });

  @override
  List<Object?> get props => [phone, code, mode];

  @override
  String toString() => 'VerifyOtpParams($phone, $mode, code: ***)';
}

import 'package:equatable/equatable.dart';

/// The two tabs of the sign-in screen. Both send a code; [signup] also
/// tells the server to create the account when the code is confirmed.
enum AuthMode {
  login('login'),
  signup('signup');

  const AuthMode(this.wire);

  final String wire;
}

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

/// Limits on the family name a new account is created with.
class FamilyName {
  FamilyName._();

  static const int minLength = 3;
  static const int maxLength = 60;
}

class RequestOtpParams extends Equatable {
  /// E.164, as the phone field reports it (`+96551502244`).
  final String phone;

  final AuthMode mode;

  /// Required for [AuthMode.signup]; ignored for a sign-in.
  final String? fullName;

  const RequestOtpParams({
    required this.phone,
    required this.mode,
    this.fullName,
  });

  @override
  List<Object?> get props => [phone, mode, fullName];
}

class VerifyOtpParams extends Equatable {
  final String requestId;
  final String code;

  const VerifyOtpParams({required this.requestId, required this.code});

  @override
  List<Object?> get props => [requestId, code];
}

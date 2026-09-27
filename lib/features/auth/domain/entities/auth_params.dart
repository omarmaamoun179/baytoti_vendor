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

/// The business and its first store — the vendor half of
/// `POST /auth/vendor/register`. For a producing family, the business is
/// the family.
///
/// Only [businessName] and [storeName] are required; the rest may be left
/// blank, and a blank one is not sent. Limits mirror the OpenAPI
/// `VendorRegisterRequest`, so the fields and the wire cannot drift apart.
class VendorDetails extends Equatable {
  static const int businessNameMinLength = 3;
  static const int businessNameMaxLength = 255;
  static const int businessPhoneMaxLength = 20;
  static const int businessEmailMaxLength = 255;
  static const int commercialLicenseMaxLength = 255;
  static const int civilIdMaxLength = 255;
  static const int bankAccountMaxLength = 255;
  static const int ibanMaxLength = 255;
  static const int addressMaxLength = 1000;
  static const int storeNameMinLength = 3;
  static const int storeNameMaxLength = 255;
  static const int storeDescriptionMaxLength = 5000;

  final String businessName;

  /// E.164 as the phone field reports it, or empty.
  final String businessPhone;

  final String businessEmail;
  final String commercialLicense;
  final String civilId;
  final String bankAccount;
  final String iban;
  final String address;
  final String storeName;
  final String storeDescription;

  const VendorDetails({
    this.businessName = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.commercialLicense = '',
    this.civilId = '',
    this.bankAccount = '',
    this.iban = '',
    this.address = '',
    this.storeName = '',
    this.storeDescription = '',
  });

  @override
  List<Object?> get props => [
        businessName,
        businessPhone,
        businessEmail,
        commercialLicense,
        civilId,
        bankAccount,
        iban,
        address,
        storeName,
        storeDescription,
      ];
}

/// What the sign-up tab adds to the number: the rest of the
/// `VendorRegisterRequest` — the account, and the [vendor] behind it.
///
/// The API marks `phone` nullable, but the code that finishes sign-up is
/// sent to it, so the form requires one.
class SignupDetails extends Equatable {
  static const int nameMinLength = 3;
  static const int nameMaxLength = 100;
  static const int emailMaxLength = 255;

  /// The API's `password` minimum; the form's strength rule is stricter.
  static const int passwordMinLength = 8;

  /// The account holder's own name.
  final String name;

  final String email;
  final String password;
  final String passwordConfirmation;
  final VendorDetails vendor;

  const SignupDetails({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.vendor,
  });

  @override
  List<Object?> get props =>
      [name, email, password, passwordConfirmation, vendor];

  @override
  String toString() => 'SignupDetails($name, $email, password: ***)';
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

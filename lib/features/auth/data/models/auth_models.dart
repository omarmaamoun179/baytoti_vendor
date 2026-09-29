import '../../../../core/network/multipart_body.dart';
import '../../../../core/utils/json_read.dart';
import '../../../../core/utils/validators/validator_logic.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/otp_challenge.dart';
import 'vendor_user_model.dart';

/// The code after the last colon of a request-otp message —
/// `"OTP sent successfully. demo otp :561228"` → `561228`. Null when nothing
/// but digits follows it, so ordinary prose with a colon is not read as a
/// code.
String? demoOtpFrom(String message) {
  final colon = message.lastIndexOf(':');
  if (colon == -1) return null;

  final code = message.substring(colon + 1).trim();
  return RegExp(r'^\d+$').hasMatch(code) ? code : null;
}

/// A sent code. The answer does not repeat where the code went, so [phone]
/// and [mode] come from the request.
class OtpChallengeModel extends OtpChallenge {
  const OtpChallengeModel({
    required super.phone,
    required super.mode,
    super.digits,
    super.expiresIn,
    super.resendAfter,
    super.demoCode,
  });

  /// The fixtures' answer:
  ///
  /// ```json
  /// {"expires_in": 120, "resend_after": 30, "digits": 4, "demo_code": "1234"}
  /// ```
  factory OtpChallengeModel.fromJson(
    Map<String, dynamic> json, {
    required String phone,
    required AuthMode mode,
  }) {
    return OtpChallengeModel(
      phone: phone,
      mode: mode,
      digits: asInt(json['digits']) ?? OtpChallenge.codeLength,
      expiresIn: Duration(seconds: asInt(json['expires_in']) ?? 180),
      resendAfter: Duration(seconds: asInt(json['resend_after']) ?? 60),
      demoCode: asString(json['demo_code']),
    );
  }

  /// `POST /auth/request-otp` on the live API, which answers `data: null`
  /// and says only that the code went out. While SMS is stubbed the code
  /// ends the message (`"… demo otp :561228"`), and its length is trusted
  /// over [OtpChallenge.codeLength] for the boxes.
  factory OtpChallengeModel.fromMessage(
    String message, {
    required String phone,
    required AuthMode mode,
  }) {
    final demoCode = demoOtpFrom(message);

    return OtpChallengeModel(
      phone: phone,
      mode: mode,
      digits: demoCode?.length ?? OtpChallenge.codeLength,
      demoCode: demoCode,
    );
  }
}

/// The two halves of a verified code — a bearer token and the account —
/// either of which an answer may leave out.
///
/// The spec types `/auth/verify-otp` only as "object", so the shapes a
/// Sanctum controller uses are all read:
///
/// ```json
/// {"user": {...}, "token": "1|abc"}
/// {"id": 1, "name": "...", "access_token": "1|abc"}
/// {"user": {...}, "token": {"access_token": "1|abc"}}
/// ```
///
/// The fixtures answer `{"access_token", "refresh_token", "is_new_user",
/// "user"}`. The repository decides what a missing half means.
class AuthPayloadModel {
  final String? accessToken;
  final String? refreshToken;
  final bool isNewUser;
  final VendorUserModel? user;

  const AuthPayloadModel({
    required this.accessToken,
    this.refreshToken,
    this.isNewUser = false,
    required this.user,
  });

  factory AuthPayloadModel.fromJson(Map<String, dynamic> json) {
    // Nested under `user` when the payload wraps it; the payload itself when
    // the controller returns the resource with the token beside it.
    final userJson = json['user'] is Map ? asMap(json['user']) : json;

    return AuthPayloadModel(
      accessToken: _tokenIn(json),
      refreshToken: asString(json['refresh_token']),
      isNewUser: asBool(json['is_new_user']) ?? false,
      // `id` is what separates an account from a wrapper that merely carries
      // a token.
      user: asString(userJson['id']) == null
          ? null
          : VendorUserModel.fromJson(userJson),
    );
  }

  /// The flat keys first, then `token` as an object.
  static String? _tokenIn(Map<String, dynamic> json) {
    for (final key in const ['access_token', 'token', 'plain_text_token']) {
      if (asString(json[key]) case final token?) return token;
    }

    final nested = asMap(json['token']);
    for (final key in const ['access_token', 'plain_text_token', 'token']) {
      if (asString(nested[key]) case final token?) return token;
    }
    return null;
  }
}

/// The body of `POST /auth/request-otp`: the number's digits, as the API's
/// `^[0-9]{8,15}$` wants them. The country code is already in them — the
/// phone field reports E.164 — so nothing is added.
Map<String, dynamic> requestOtpBody(String phone) => {
      'phone': digitsOnly(phone),
    };

/// The body of `POST /auth/verify-otp`.
Map<String, dynamic> verifyOtpBody(VerifyOtpParams params) => {
      'phone': digitsOnly(params.phone),
      'otp': digitsOnly(params.code),
    };

/// The body of `POST /auth/vendor/register`, per the OpenAPI
/// `VendorRegisterRequest`.
///
/// Every number goes out as digits, as the OTP pair takes it. An optional
/// field left blank is left out rather than sent empty: an empty string is
/// a value the server would store, or refuse as an invalid email.
/// [deviceName] names the token the account is issued, for the family's
/// list of signed-in devices. A chosen photo is the `avatar` file, which
/// makes the body multipart ([multipartBodyFrom]).
Map<String, dynamic> vendorRegisterBody(
  String phone,
  SignupDetails signup, {
  String? deviceName,
}) {
  final vendor = signup.vendor;
  final businessPhone = digitsOnly(vendor.businessPhone);

  return {
    'name': signup.name.trim(),
    'email': signup.email.trim(),
    'phone': digitsOnly(phone),
    'password': signup.password,
    'password_confirmation': signup.passwordConfirmation,
    'device_name': ?_blankToNull(deviceName),
    'business_name': vendor.businessName.trim(),
    'business_phone': ?_blankToNull(businessPhone),
    'business_email': ?_blankToNull(vendor.businessEmail),
    'commercial_license': ?_blankToNull(vendor.commercialLicense),
    'civil_id': ?_blankToNull(vendor.civilId),
    'bank_account': ?_blankToNull(vendor.bankAccount),
    // Written in capitals with no spaces, as banks print it grouped.
    'iban': ?_blankToNull(vendor.iban.replaceAll(' ', '').toUpperCase()),
    'address': ?_blankToNull(vendor.address),
    'store_name': vendor.storeName.trim(),
    'store_description': ?_blankToNull(vendor.storeDescription),
    if (signup.avatarPath case final avatar?) 'avatar': FileUpload(avatar),
  };
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

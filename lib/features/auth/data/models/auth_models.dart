import '../../../../core/utils/json_read.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/otp_challenge.dart';
import 'vendor_user_model.dart';

/// `/auth/request-otp` and `/auth/resend-otp`:
///
/// ```json
/// {"request_id": "otp_7f3a", "expires_in": 120, "resend_after": 30,
///  "digits": 4}
/// ```
///
/// The answer does not repeat where the code went, so [phone] and [mode]
/// come from the request.
class OtpChallengeModel extends OtpChallenge {
  const OtpChallengeModel({
    required super.requestId,
    required super.phone,
    required super.mode,
    super.digits,
    super.expiresIn,
    super.resendAfter,
    super.demoCode,
  });

  factory OtpChallengeModel.fromJson(
    Map<String, dynamic> json, {
    required String phone,
    required AuthMode mode,
  }) {
    return OtpChallengeModel(
      requestId: requireString(json['request_id'], 'request_id'),
      phone: phone,
      mode: mode,
      digits: asInt(json['digits']) ?? 4,
      expiresIn: Duration(seconds: asInt(json['expires_in']) ?? 120),
      resendAfter: Duration(seconds: asInt(json['resend_after']) ?? 30),
      // Fixtures only — see [OtpChallenge.demoCode].
      demoCode: asString(json['demo_code']),
    );
  }
}

/// `/auth/verify-otp`:
///
/// ```json
/// {"access_token": "eyJ…", "refresh_token": "eyJ…", "expires_in": 3600,
///  "is_new_user": false, "user": {…}}
/// ```
class AuthPayloadModel {
  final String accessToken;
  final String? refreshToken;
  final bool isNewUser;
  final VendorUserModel user;

  const AuthPayloadModel({
    required this.accessToken,
    this.refreshToken,
    required this.isNewUser,
    required this.user,
  });

  /// Throws when the token or the account is missing: a session without
  /// either cannot be opened, and that is a malformed answer, not a login.
  factory AuthPayloadModel.fromJson(Map<String, dynamic> json) {
    return AuthPayloadModel(
      accessToken: requireString(json['access_token'], 'access_token'),
      refreshToken: asString(json['refresh_token']),
      isNewUser: asBool(json['is_new_user']) ?? false,
      user: VendorUserModel.fromJson(asMap(json['user'])),
    );
  }
}

/// The body of `/auth/request-otp`.
Map<String, dynamic> requestOtpBody(RequestOtpParams params) => {
      'phone': params.phone,
      'mode': params.mode.wire,
      if (params.mode == AuthMode.signup && params.fullName != null)
        'full_name': params.fullName!.trim(),
    };

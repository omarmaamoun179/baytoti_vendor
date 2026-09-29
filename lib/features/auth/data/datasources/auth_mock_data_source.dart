import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/mock/mock_session_token.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/auth_params.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';
import 'auth_data_source.dart';

/// The auth endpoints on fixtures.
///
/// Any number gets a code, and the code is always [demoCode] — the
/// challenge carries it so the OTP screen can say so. A number signs in to
/// the fixture family's account, already approved, unless it registered this
/// run: then it opens that new family, whose application is still under
/// review. The token names the account ([MockSessionToken]) so the other
/// fixtures can tell the two apart.
class AuthMockDataSource implements AuthDataSource {
  static const String demoCode = '1234';

  static const Localized _fixtureFamily =
      Localized('أسرة أم عبدالله', 'Umm Abdullah Family');

  final TokenStore _tokenStore;
  final MockLocale _locale;

  /// Families registered this run, by the digits of their number.
  final Map<String, String> _registered = {};

  /// Numbers a code was sent to and not yet spent, by their digits.
  final Set<String> _awaiting = {};

  AuthMockDataSource(this._tokenStore, this._locale);

  @override
  Future<Either<Failure, Unit>> register(String phone, SignupDetails signup) =>
      guardedRequest(
        'AuthMockDataSource.register',
        () async {
          await Future<void>.delayed(mockLatency);
          await checkAvatarSize(signup);

          final digits = _digits(phone);
          if (_registered.containsKey(digits)) {
            // What the server's unique rule says to a number used twice.
            throw const RequestException('phone_taken', statusCode: 422);
          }
          // The family is the business; its name is what the fixtures
          // greet and name the store by.
          _registered[digits] = signup.vendor.businessName.trim();
          return unit;
        },
        fallbackMessage: 'signup_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    String phone,
    AuthMode mode,
  ) =>
      guardedRequest(
        'AuthMockDataSource.requestOtp',
        () async {
          await Future<void>.delayed(mockLatency);

          _awaiting.add(_digits(phone));
          return OtpChallengeModel.fromJson(
            {
              'expires_in': 120,
              'resend_after': 30,
              'digits': demoCode.length,
              'demo_code': demoCode,
            },
            phone: phone,
            mode: mode,
          );
        },
        fallbackMessage: 'otp_send_failed',
      );

  @override
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(
    VerifyOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.verifyOtp',
        () async {
          await Future<void>.delayed(mockLatency);

          final digits = _digits(params.phone);
          if (!_awaiting.contains(digits)) {
            throw const RequestException('otp_expired', statusCode: 422);
          }
          if (params.code != demoCode) {
            throw const RequestException('otp_invalid', statusCode: 422);
          }

          final familyName = _registered[digits];
          final token = MockSessionToken(
            isNewFamily: familyName != null,
            phoneDigits: digits,
            familyName: familyName,
          );
          _awaiting.remove(digits);

          return AuthPayloadModel.fromJson({
            'access_token': token.encode(),
            'refresh_token': null,
            'is_new_user': familyName != null,
            'user': await _userJson(token),
          });
        },
        fallbackMessage: 'otp_verify_failed',
      );

  @override
  Future<Either<Failure, VendorUserModel>> getMe() => guardedRequest(
        'AuthMockDataSource.getMe',
        () async {
          await Future<void>.delayed(mockLatency);

          final token = MockSessionToken.decode(
            (await _tokenStore.read())?.accessToken,
          );
          // What the server says to a token it did not issue.
          if (token == null) throw const SessionExpiredException();

          return VendorUserModel.fromJson(await _userJson(token));
        },
        fallbackMessage: 'account_refresh_failed',
      );

  @override
  Future<Either<Failure, Unit>> logout() => guardedRequest(
        'AuthMockDataSource.logout',
        () async {
          await Future<void>.delayed(mockLatency);
          return unit;
        },
      );

  static String _digits(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  Future<Map<String, dynamic>> _userJson(MockSessionToken token) async => {
        'id': 'usr_${token.phoneDigits}',
        'full_name': token.familyName ??
            _fixtureFamily.pick(await _locale.isArabic()),
        'phone': '+${token.phoneDigits}',
        'avatar': null,
        'role': 'vendor',
      };
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/mock/mock_session_token.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/otp_challenge.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';
import 'auth_data_source.dart';

/// The auth contract on fixtures.
///
/// Any Kuwaiti number gets a code, and the code is always [demoCode] — the
/// challenge carries it so the OTP screen can say so. The sign-in tab opens
/// the fixture family's account, already approved; the sign-up tab opens a
/// new one whose application is still under review. The token names the
/// account ([MockSessionToken]) so the onboarding fixtures can tell the two
/// apart.
class AuthMockDataSource implements AuthDataSource {
  static const String demoCode = '1234';

  static const Localized _fixtureFamily =
      Localized('أسرة أم عبدالله', 'Umm Abdullah Family');

  final TokenStore _tokenStore;
  final MockLocale _locale;

  /// Every code sent this run, by request id.
  final Map<String, RequestOtpParams> _requests = {};
  int _sequence = 0;

  AuthMockDataSource(this._tokenStore, this._locale);

  @override
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    RequestOtpParams params,
  ) =>
      guardedRequest(
        'AuthMockDataSource.requestOtp',
        () async {
          await Future<void>.delayed(mockLatency);

          final requestId = 'otp_${++_sequence}';
          _requests[requestId] = params;
          return _challenge(requestId, params);
        },
        fallbackMessage: 'otp_send_failed',
      );

  @override
  Future<Either<Failure, OtpChallengeModel>> resendOtp(
    OtpChallenge challenge,
  ) =>
      guardedRequest(
        'AuthMockDataSource.resendOtp',
        () async {
          await Future<void>.delayed(mockLatency);

          final params = _requests[challenge.requestId];
          if (params == null) {
            throw const RequestException('otp_expired', statusCode: 410);
          }
          return _challenge(challenge.requestId, params);
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

          final request = _requests[params.requestId];
          if (request == null) {
            throw const RequestException('otp_expired', statusCode: 410);
          }
          if (params.code != demoCode) {
            throw const RequestException('otp_invalid', statusCode: 401);
          }

          final isNew = request.mode == AuthMode.signup;
          final token = MockSessionToken(
            isNewFamily: isNew,
            phoneDigits: request.phone.replaceAll(RegExp(r'\D'), ''),
            familyName: isNew ? request.fullName?.trim() : null,
          );
          _requests.remove(params.requestId);

          return AuthPayloadModel.fromJson({
            'access_token': token.encode(),
            'refresh_token': null,
            'expires_in': 3600,
            'is_new_user': isNew,
            'user': await _userJson(token, request.phone),
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

          return VendorUserModel.fromJson(
            await _userJson(token, '+${token.phoneDigits}'),
          );
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

  OtpChallengeModel _challenge(String requestId, RequestOtpParams params) =>
      OtpChallengeModel.fromJson(
        {
          'request_id': requestId,
          'expires_in': 120,
          'resend_after': 30,
          'digits': demoCode.length,
          'demo_code': demoCode,
        },
        phone: params.phone,
        mode: params.mode,
      );

  Future<Map<String, dynamic>> _userJson(
    MockSessionToken token,
    String phone,
  ) async =>
      {
        'id': 'usr_${token.phoneDigits}',
        'full_name': token.familyName ??
            _fixtureFamily.pick(await _locale.isArabic()),
        'phone': phone,
        'avatar': null,
        'role': 'vendor',
      };
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/multipart_body.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/auth_params.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';
import 'auth_data_source.dart';

/// The auth endpoints of the live API, one method each.
class AuthRemoteDataSource implements AuthDataSource {
  final NetworkService _networkService;

  /// What registration names the account's token (`device_name`) — the app
  /// and the platform, since the app reads no device model.
  final String? _deviceName;

  AuthRemoteDataSource(this._networkService, {this._deviceName});

  @override
  Future<Either<Failure, Unit>> register(String phone, SignupDetails signup) =>
      guardedRequest(
        'AuthRemoteDataSource.register',
        () async {
          await checkAvatarSize(signup);
          final body =
              vendorRegisterBody(phone, signup, deviceName: _deviceName);
          final response = await _networkService.post(
            ApiEndPoint.vendorRegister,
            // Public: there is no session yet to refresh.
            skipAuthRefresh: true,
            // A photo makes it multipart; without one it stays JSON.
            data: containsFileUpload(body)
                ? await multipartBodyFrom(body)
                : body,
          );
          // Only whether it succeeded is read. The answer carries no token,
          // and an account shaped otherwise than expected must not turn one
          // the server made into a failure the family retries — the retry
          // would be refused as a duplicate email.
          checkedResponse(response);
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
        'AuthRemoteDataSource.requestOtp',
        () async {
          final response = await _networkService.post(
            ApiEndPoint.requestOtp,
            // Public: the number in the body identifies the account.
            skipAuthRefresh: true,
            data: requestOtpBody(phone),
          );
          // `data` is null — the message is all there is, and it carries the
          // code while SMS delivery is stubbed.
          return OtpChallengeModel.fromMessage(
            checkedResponse(response).message,
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
        'AuthRemoteDataSource.verifyOtp',
        () async {
          final response = await _networkService.post(
            ApiEndPoint.verifyOtp,
            skipAuthRefresh: true,
            data: verifyOtpBody(params),
          );
          // Either half may be absent; the repository decides what that
          // means rather than this failing a code the server accepted.
          return AuthPayloadModel.fromJson(checkedResponse(response).dataMap);
        },
        fallbackMessage: 'otp_verify_failed',
      );

  @override
  Future<Either<Failure, VendorUserModel>> getMe() => guardedRequest(
        'AuthRemoteDataSource.getMe',
        () async {
          final response = await _networkService.get(ApiEndPoint.me);
          final data = checkedResponse(response).dataMap;

          // Some controllers wrap the resource in `user`.
          final user = data['user'] is Map
              ? Map<String, dynamic>.from(data['user'] as Map)
              : data;
          return VendorUserModel.fromJson(user);
        },
        fallbackMessage: 'account_refresh_failed',
      );

  @override
  Future<Either<Failure, Unit>> logout() => guardedRequest(
        'AuthRemoteDataSource.logout',
        () async {
          checkedResponse(await _networkService.post(ApiEndPoint.logout));
          return unit;
        },
      );
}

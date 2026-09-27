import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/otp_challenge.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';

/// The auth endpoints of the API contract. [AuthMockDataSource] answers
/// them from fixtures; a remote source against `ApiEndPoint.requestOtp` and
/// the rest takes its place when the API exists. The request and verify
/// pair are public — send them with `skipAuthRefresh: true`, so a 401 reads
/// as a wrong code rather than an expired session.
abstract class AuthDataSource {
  /// `POST /auth/request-otp`.
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    RequestOtpParams params,
  );

  /// `POST /auth/resend-otp` — a fresh code for the same request.
  Future<Either<Failure, OtpChallengeModel>> resendOtp(OtpChallenge challenge);

  /// `POST /auth/verify-otp`. A wrong code is `401 otp_invalid`.
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(VerifyOtpParams params);

  /// `GET /me`.
  Future<Either<Failure, VendorUserModel>> getMe();

  /// `POST /auth/logout`.
  Future<Either<Failure, Unit>> logout();
}

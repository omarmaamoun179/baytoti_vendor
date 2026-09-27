import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/auth_params.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';

/// The auth endpoints. [AuthRemoteDataSource] calls the live API;
/// [AuthMockDataSource] answers the same calls from fixtures. The three
/// public calls go out with `skipAuthRefresh: true`, so a 401 reads as a
/// refusal rather than an expired session.
abstract class AuthDataSource {
  /// `POST /auth/vendor/register` — the account, its business and its first
  /// store. No token comes back: the code issues it.
  Future<Either<Failure, Unit>> register(String phone, SignupDetails signup);

  /// `POST /auth/request-otp` — also every resend.
  Future<Either<Failure, OtpChallengeModel>> requestOtp(
    String phone,
    AuthMode mode,
  );

  /// `POST /auth/verify-otp`. A wrong code is a 422 on `otp`.
  Future<Either<Failure, AuthPayloadModel>> verifyOtp(VerifyOtpParams params);

  /// `GET /auth/me`.
  Future<Either<Failure, VendorUserModel>> getMe();

  /// `POST /auth/logout`.
  Future<Either<Failure, Unit>> logout();
}

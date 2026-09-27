import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/auth_params.dart';
import '../entities/auth_session.dart';
import '../entities/otp_challenge.dart';
import '../entities/vendor_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, OtpChallenge>> requestOtp(RequestOtpParams params);

  Future<Either<Failure, OtpChallenge>> resendOtp(OtpChallenge challenge);

  /// Confirms the code and keeps the session on the device.
  Future<Either<Failure, AuthSession>> verifyOtp(VerifyOtpParams params);

  /// The account kept on the device, or null when nobody is signed in.
  /// Touches only the device.
  Future<Either<Failure, VendorUser?>> restoreSession();

  /// `GET /me`, kept on the device on the way through.
  Future<Either<Failure, VendorUser>> refreshAccount();

  /// Tells the server, then forgets the session whatever it answered.
  Future<Either<Failure, Unit>> logout();

  /// Forgets the session without telling the server — for a token the
  /// server has already refused.
  Future<Either<Failure, Unit>> clearSession();
}

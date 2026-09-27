import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/vendor_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';

/// Orchestrates the server and the device. No try/catch: both sources
/// already answer with `Either`, so each step folds into the next.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._dataSource, this._localDataSource);

  @override
  Future<Either<Failure, OtpChallenge>> requestOtp(RequestOtpParams params) =>
      _dataSource.requestOtp(params);

  @override
  Future<Either<Failure, OtpChallenge>> resendOtp(OtpChallenge challenge) =>
      _dataSource.resendOtp(challenge);

  /// A confirmed code is a session only once it is kept: a token the app
  /// holds in memory alone would sign the vendor out on the next launch.
  @override
  Future<Either<Failure, AuthSession>> verifyOtp(
    VerifyOtpParams params,
  ) async {
    final result = await _dataSource.verifyOtp(params);

    return result.fold<Future<Either<Failure, AuthSession>>>(
      (failure) async => Left(failure),
      (payload) async {
        final kept = await _localDataSource.cacheSession(
          accessToken: payload.accessToken,
          refreshToken: payload.refreshToken,
          user: payload.user,
        );
        return kept.map(
          (_) => AuthSession(user: payload.user, isNewUser: payload.isNewUser),
        );
      },
    );
  }

  @override
  Future<Either<Failure, VendorUser?>> restoreSession() async {
    final result = await _localDataSource.readSession();

    return result.fold<Future<Either<Failure, VendorUser?>>>(
      (failure) async {
        // A stored session that cannot be read is dropped, so the next
        // launch is not stuck on the same failure. The failure still goes up.
        await _localDataSource.clear();
        return Left(failure);
      },
      (user) async => Right(user),
    );
  }

  @override
  Future<Either<Failure, VendorUser>> refreshAccount() async {
    final result = await _dataSource.getMe();

    return result.fold<Future<Either<Failure, VendorUser>>>(
      (failure) async => Left(failure),
      (user) async {
        final kept = await _localDataSource.cacheUser(user);
        return kept.map((_) => user);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    // Signing out is local. A server that refuses the call, or a network that
    // is down, must not leave the session on the device — so the remote
    // result is deliberately not what this returns.
    await _dataSource.logout();
    return clearSession();
  }

  @override
  Future<Either<Failure, Unit>> clearSession() => _localDataSource.clear();
}

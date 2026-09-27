import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/vendor_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/auth_models.dart';
import '../models/vendor_user_model.dart';

/// Orchestrates the server and the device. No try/catch: both sources
/// already answer with `Either`, so each step folds into the next.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._dataSource, this._localDataSource);

  /// A sign-in asks for the code. A sign-up first creates the account —
  /// registration issues no token, the code does — and then asks.
  @override
  Future<Either<Failure, OtpChallenge>> requestOtp(
    RequestOtpParams params,
  ) async {
    final signup = params.signup;
    if (params.mode == AuthMode.login || signup == null) {
      return _dataSource.requestOtp(params.phone, params.mode);
    }

    final registered = await _dataSource.register(params.phone, signup);

    return registered.fold<Future<Either<Failure, OtpChallenge>>>(
      (failure) async => Left(failure),
      (_) async {
        final sent = await _dataSource.requestOtp(params.phone, params.mode);
        // The account exists now, so sending the form again would be refused
        // as a duplicate. The family is told to carry on from sign-in, where
        // the same number gets a code.
        return sent.leftMap(
          (failure) => switch (failure) {
            NetworkFailure() => NetworkFailure(
                message: 'signup_code_failed'.tr(),
                statusCode: failure.statusCode,
              ),
            _ => ServerFailure(
                message: 'signup_code_failed'.tr(),
                statusCode: failure.statusCode,
              ),
          },
        );
      },
    );
  }

  /// Another code to the same number. Never registers again, whichever tab
  /// sent the first.
  @override
  Future<Either<Failure, OtpChallenge>> resendOtp(OtpChallenge challenge) =>
      _dataSource.requestOtp(challenge.phone, challenge.mode);

  /// A confirmed code is a session only once it is kept: a token the app
  /// holds in memory alone would sign the family out on the next launch.
  @override
  Future<Either<Failure, AuthSession>> verifyOtp(
    VerifyOtpParams params,
  ) async {
    final result = await _dataSource.verifyOtp(params);

    return result.fold<Future<Either<Failure, AuthSession>>>(
      (failure) async => Left(failure),
      (payload) => _open(payload, isNewUser: params.mode == AuthMode.signup),
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
  Future<Either<Failure, VendorUser>> refreshAccount() => _readAccount();

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

  /// Keeps what a confirmed code returned. A token without an account is
  /// kept first and the account read with it; an answer without a token
  /// cannot open anything.
  Future<Either<Failure, AuthSession>> _open(
    AuthPayloadModel payload, {
    required bool isNewUser,
  }) async {
    final token = payload.accessToken;
    if (token == null) {
      return Left(UnexpectedFailure(message: 'auth_token_missing'.tr()));
    }

    final user = payload.user;
    if (user != null) {
      final kept = await _localDataSource.cacheSession(
        accessToken: token,
        refreshToken: payload.refreshToken,
        user: user,
      );
      return kept.map(
        (_) => AuthSession(
          user: user,
          isNewUser: isNewUser || payload.isNewUser,
        ),
      );
    }

    final kept = await _localDataSource.cacheToken(
      accessToken: token,
      refreshToken: payload.refreshToken,
    );

    return kept.fold<Future<Either<Failure, AuthSession>>>(
      (failure) async => Left(failure),
      (_) async {
        final account = await _readAccount();

        return account.fold<Future<Either<Failure, AuthSession>>>(
          (failure) async {
            // A token nobody can be shown for is no session; it goes, so a
            // relaunch does not resume half of one.
            await _localDataSource.clear();
            return Left(failure);
          },
          (user) async => Right(AuthSession(user: user, isNewUser: isNewUser)),
        );
      },
    );
  }

  /// `GET /auth/me`, kept on the device on the way through.
  Future<Either<Failure, VendorUserModel>> _readAccount() async {
    final result = await _dataSource.getMe();

    return result.fold<Future<Either<Failure, VendorUserModel>>>(
      (failure) async => Left(failure),
      (user) async {
        final kept = await _localDataSource.cacheUser(user);
        return kept.map((_) => user);
      },
    );
  }
}

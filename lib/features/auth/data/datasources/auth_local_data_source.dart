import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/vendor_user_model.dart';

/// The session on the device: the token through [TokenStore], the account
/// in secure storage beside it.
abstract class AuthLocalDataSource {
  Future<Either<Failure, Unit>> cacheSession({
    required String accessToken,
    String? refreshToken,
    required VendorUserModel user,
  });

  /// Keeps a token alone — for a code the server confirmed without naming
  /// the account, which is then read with it. Not a session until
  /// [cacheUser] follows: [readSession] wants both.
  Future<Either<Failure, Unit>> cacheToken({
    required String accessToken,
    String? refreshToken,
  });

  /// Replaces the kept account without touching the token.
  Future<Either<Failure, Unit>> cacheUser(VendorUserModel user);

  /// The kept account, or null when there is no whole session — no token,
  /// or no account beside it.
  Future<Either<Failure, VendorUserModel?>> readSession();

  /// Wipes token and account together. One without the other is a session
  /// that looks signed in and cannot make a call.
  Future<Either<Failure, Unit>> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// The token goes through [TokenStore] because that is what the network
  /// layer reads for the Authorization header — writing around it would make
  /// a session the app believes in and the API rejects.
  final TokenStore _tokenStore;

  final SecureStorageService _secureStorage;

  AuthLocalDataSourceImpl(this._tokenStore, this._secureStorage);

  @override
  Future<Either<Failure, Unit>> cacheSession({
    required String accessToken,
    String? refreshToken,
    required VendorUserModel user,
  }) =>
      guardedStorage(
        'AuthLocalDataSource.cacheSession',
        () async {
          await _tokenStore.save(
            TokenPair(accessToken: accessToken, refreshToken: refreshToken),
          );
          await _writeUser(user);
          return unit;
        },
        fallbackMessage: 'session_save_failed',
      );

  @override
  Future<Either<Failure, Unit>> cacheToken({
    required String accessToken,
    String? refreshToken,
  }) =>
      guardedStorage(
        'AuthLocalDataSource.cacheToken',
        () async {
          await _tokenStore.save(
            TokenPair(accessToken: accessToken, refreshToken: refreshToken),
          );
          return unit;
        },
        fallbackMessage: 'session_save_failed',
      );

  @override
  Future<Either<Failure, Unit>> cacheUser(VendorUserModel user) =>
      guardedStorage(
        'AuthLocalDataSource.cacheUser',
        () async {
          await _writeUser(user);
          return unit;
        },
        fallbackMessage: 'session_save_failed',
      );

  @override
  Future<Either<Failure, VendorUserModel?>> readSession() =>
      guardedStorage('AuthLocalDataSource.readSession', () async {
        final token = (await _tokenStore.read())?.accessToken;
        if (token == null || token.isEmpty) return null;

        // Parsed inside the guard: an account written by an older build that
        // no longer decodes is reported, not silently dropped.
        final raw =
            await _secureStorage.read(key: SecureStorageService.userKey);
        if (raw == null || raw.isEmpty) return null;

        return VendorUserModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      });

  @override
  Future<Either<Failure, Unit>> clear() =>
      guardedStorage(
        'AuthLocalDataSource.clear',
        () async {
          await _tokenStore.clear();
          await _secureStorage.delete(key: SecureStorageService.userKey);
          return unit;
        },
        fallbackMessage: 'session_clear_failed',
      );

  Future<void> _writeUser(VendorUserModel user) => _secureStorage.write(
        key: SecureStorageService.userKey,
        value: jsonEncode(user.toJson()),
      );
}

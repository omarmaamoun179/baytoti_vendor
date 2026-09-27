import 'package:baytoti_vendor/core/app/session_notifier.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/core/mock/mock_session_token.dart';
import 'package:baytoti_vendor/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti_vendor/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:baytoti_vendor/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baytoti_vendor/features/auth/domain/entities/auth_params.dart';
import 'package:baytoti_vendor/features/auth/domain/usecases/auth_usecases.dart';
import 'package:baytoti_vendor/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytoti_vendor/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late MemoryTokenStore tokens;
  late MemorySecureStorage storage;
  late SessionNotifier session;
  late AuthCubit cubit;

  AuthCubit build() {
    final repository = AuthRepositoryImpl(
      AuthMockDataSource(tokens, MockLocale(FakeCacheService())),
      AuthLocalDataSourceImpl(tokens, storage),
    );
    return AuthCubit(
      RequestOtpUseCase(repository),
      ResendOtpUseCase(repository),
      VerifyOtpUseCase(repository),
      RestoreSessionUseCase(repository),
      RefreshAccountUseCase(repository),
      LogoutUseCase(repository),
      ClearSessionUseCase(repository),
      session,
    );
  }

  setUp(() {
    tokens = MemoryTokenStore();
    storage = MemorySecureStorage();
    session = SessionNotifier();
    cubit = build();
  });

  tearDown(() => cubit.close());

  const login = RequestOtpParams(phone: '+96551502244', mode: AuthMode.login);

  test('a sent code leaves the cubit waiting on it', () async {
    await cubit.requestOtp(login);

    expect(cubit.state.status, AuthStatus.codeSent);
    expect(cubit.state.challenge?.phone, '+96551502244');
    expect(cubit.state.challenge?.demoCode, AuthMockDataSource.demoCode);
  });

  test('a wrong code keeps the family on the code, signed out', () async {
    await cubit.requestOtp(login);
    await cubit.verifyOtp('0000');

    expect(cubit.state.status, AuthStatus.error);
    expect(cubit.state.errorMessage, 'otp_invalid');
    expect(cubit.state.challenge, isNotNull);
    expect(session.isAuthenticated, isFalse);
    expect(tokens.tokens, isNull);
  });

  test('the right code opens and keeps the session', () async {
    await cubit.requestOtp(login);
    await cubit.verifyOtp(AuthMockDataSource.demoCode);

    expect(cubit.state.hasSession, isTrue);
    expect(session.isAuthenticated, isTrue);

    final token = MockSessionToken.decode(tokens.tokens?.accessToken);
    expect(token?.isNewFamily, isFalse);
  });

  test('signing up opens an account for a new family by its name', () async {
    await cubit.requestOtp(const RequestOtpParams(
      phone: '+96566001122',
      mode: AuthMode.signup,
      fullName: 'مطبخ سارة',
    ));
    await cubit.verifyOtp(AuthMockDataSource.demoCode);

    expect(cubit.state.user?.fullName, 'مطبخ سارة');
    final token = MockSessionToken.decode(tokens.tokens?.accessToken);
    expect(token?.isNewFamily, isTrue);
    expect(token?.familyName, 'مطبخ سارة');
  });

  test('a kept session is restored at the next launch', () async {
    await cubit.requestOtp(login);
    await cubit.verifyOtp(AuthMockDataSource.demoCode);
    await cubit.close();

    // A new launch: fresh cubit and notifier over the same device storage.
    session = SessionNotifier();
    cubit = build();
    await cubit.restoreSession();

    expect(cubit.state.hasSession, isTrue);
    expect(session.isAuthenticated, isTrue);
  });

  test('a launch with nothing kept resolves signed out', () async {
    await cubit.restoreSession();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(session.isResolved, isTrue);
    expect(session.isAuthenticated, isFalse);
  });

  test('signing out forgets the token and tells the router', () async {
    await cubit.requestOtp(login);
    await cubit.verifyOtp(AuthMockDataSource.demoCode);
    await cubit.logout();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(session.isAuthenticated, isFalse);
    expect(tokens.tokens, isNull);
  });
}

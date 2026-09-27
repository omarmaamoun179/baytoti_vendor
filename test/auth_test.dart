import 'package:baytoti_vendor/core/app/session_notifier.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/core/mock/mock_session_token.dart';
import 'package:baytoti_vendor/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti_vendor/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:baytoti_vendor/features/auth/data/models/auth_models.dart';
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
      signup: SignupDetails(
        name: 'سارة العلي',
        email: 'sara@example.com',
        password: 'kitchen2026',
        passwordConfirmation: 'kitchen2026',
        vendor: VendorDetails(
          businessName: 'مطبخ سارة',
          storeName: 'مطبخ سارة',
        ),
      ),
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

  group('the live API\'s answers', () {
    test('the demo code is read off the end of the message', () {
      expect(demoOtpFrom('OTP sent successfully. demo otp :561228'), '561228');
      expect(demoOtpFrom('OTP sent successfully.'), isNull);
      expect(demoOtpFrom('Note: check your phone'), isNull);
    });

    test('a sent code takes its length from the demo code', () {
      final challenge = OtpChallengeModel.fromMessage(
        'OTP sent successfully. demo otp :5612',
        phone: '+96551502244',
        mode: AuthMode.login,
      );
      expect(challenge.digits, 4);
      expect(challenge.demoCode, '5612');
    });

    test('a session is read under user with the token beside it', () {
      final payload = AuthPayloadModel.fromJson({
        'user': {'id': 23, 'name': 'أسرة سارة', 'phone': '96566001122'},
        'token': '1|abc',
      });
      expect(payload.accessToken, '1|abc');
      expect(payload.user?.id, '23');
      expect(payload.user?.fullName, 'أسرة سارة');
    });

    test('a token alone is kept apart from the account', () {
      final payload = AuthPayloadModel.fromJson({
        'token': {'access_token': '2|xyz'},
      });
      expect(payload.accessToken, '2|xyz');
      expect(payload.user, isNull);
    });

    test('the number goes out as digits only', () {
      expect(requestOtpBody('+965 5150 2244'), {'phone': '96551502244'});
    });

    test('registration sends every field filled, and no blank one', () {
      final body = vendorRegisterBody(
        '+96566001122',
        const SignupDetails(
          name: ' سارة العلي ',
          email: 'sara@example.com',
          password: 'kitchen2026',
          passwordConfirmation: 'kitchen2026',
          vendor: VendorDetails(
            businessName: 'مطبخ سارة',
            businessPhone: '+965 2266 1100',
            iban: 'kw81 cbku 0000',
            storeName: 'حلويات سارة',
            storeDescription: '  ',
          ),
        ),
        deviceName: 'Baytouti Vendor · ios',
      );

      expect(body, {
        'name': 'سارة العلي',
        'email': 'sara@example.com',
        'phone': '96566001122',
        'password': 'kitchen2026',
        'password_confirmation': 'kitchen2026',
        'device_name': 'Baytouti Vendor · ios',
        'business_name': 'مطبخ سارة',
        'business_phone': '96522661100',
        'iban': 'KW81CBKU0000',
        'store_name': 'حلويات سارة',
      });
    });
  });
}

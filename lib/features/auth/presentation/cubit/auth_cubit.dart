import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/app/session_notifier.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

/// Owns the session: sending and checking the sign-in code, restoring the
/// session at startup, re-reading the account, and signing out.
///
/// App-wide — the router, the onboarding gate and the store tab all read
/// it, and a second instance would let them disagree about who is signed
/// in. It is also the only caller of [SessionNotifier]'s writes.
class AuthCubit extends BaseCubit<AuthState> {
  final RequestOtpUseCase _requestOtp;
  final ResendOtpUseCase _resendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final RestoreSessionUseCase _restoreSession;
  final RefreshAccountUseCase _refreshAccount;
  final LogoutUseCase _logout;
  final ClearSessionUseCase _clearSession;
  final SessionNotifier _sessionNotifier;

  AuthCubit(
    this._requestOtp,
    this._resendOtp,
    this._verifyOtp,
    this._restoreSession,
    this._refreshAccount,
    this._logout,
    this._clearSession,
    this._sessionNotifier,
  ) : super(const AuthState());

  /// Reads the stored session. Resolves the notifier on every branch, so the
  /// router never waits on a decision that does not come.
  ///
  /// Touches only the device, never the network: it runs before `runApp`,
  /// and a request that early creates the requests inspector's controller
  /// disabled, hiding every later call.
  Future<void> restoreSession() async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _restoreSession(NoParams());

    result.fold(
      // A session that could not be read is no session; the repository has
      // already cleared it, and there is nothing for the vendor to act on.
      (_) => _endSession(),
      (user) {
        if (user == null) return _endSession();
        emit(state.signedIn(user));
        _sessionNotifier.signedIn();
      },
    );
  }

  /// `POST /auth/request-otp` — after `POST /auth/vendor/register` for a
  /// sign-up. On success the state carries the challenge and the sign-in
  /// screen moves on to the code.
  Future<void> requestOtp(RequestOtpParams params) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: AuthStatus.loading));

    (await _requestOtp(params)).fold(
      _emitFailure,
      (challenge) => emit(AuthState(
        status: AuthStatus.codeSent,
        challenge: challenge,
      )),
    );
  }

  /// A fresh code for the challenge in hand. A no-op without one.
  Future<void> resendOtp() async {
    final challenge = state.challenge;
    if (challenge == null || state.isLoading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    (await _resendOtp(challenge)).fold(
      _emitFailure,
      (fresh) => emit(state.copyWith(
        status: AuthStatus.codeSent,
        challenge: fresh,
      )),
    );
  }

  /// `POST /auth/verify-otp` with [code]; when the server accepts it, the
  /// session opens and the router takes the vendor in.
  Future<void> verifyOtp(String code) async {
    final challenge = state.challenge;
    if (challenge == null || state.isLoading) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _verifyOtp(VerifyOtpParams(
      phone: challenge.phone,
      code: code,
      mode: challenge.mode,
    ));

    result.fold(
      _emitFailure,
      (session) {
        emit(state.signedIn(session.user));
        _sessionNotifier.signedIn();
      },
    );
  }

  /// Re-reads the account. A failure keeps the kept account — a flaky
  /// network is no reason to sign anyone out; a refused token is.
  Future<void> refreshAccount() async {
    if (!state.hasSession) return;

    final result = await _refreshAccount(NoParams());

    // Signed out while the read was out, so there is no account to update.
    if (!state.hasSession) return;

    result.fold(
      (failure) {
        if (failure.statusCode == 401) sessionExpired();
      },
      (user) => emit(state.signedIn(user)),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _logout(NoParams());

    // Signed out either way: the session is gone from memory, and a device
    // that could not wipe it is worth saying, not worth staying signed in.
    result.fold(
      (failure) => _endSession(errorMessage: failure.message),
      (_) => _endSession(),
    );
  }

  /// The server refused the session's token. The network layer calls this
  /// once it has stopped sending the token; this forgets the rest of the
  /// session. Nothing is sent: a logout with that token would be refused too.
  Future<void> sessionExpired() async {
    // Already over. Calls refused at the same moment each report it.
    if (!state.hasSession) return;

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _clearSession(NoParams());

    result.fold(
      (failure) => _endSession(errorMessage: failure.message),
      (_) => _endSession(),
    );
  }

  /// Drops the error and any code in flight — when the vendor goes back to
  /// the phone number, or switches between signing in and signing up.
  void reset() {
    if (state.hasSession) return;
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _endSession({String? errorMessage}) {
    emit(state.signedOut(errorMessage: errorMessage));
    _sessionNotifier.signedOut();
  }

  void _emitFailure(Failure failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      ));
}

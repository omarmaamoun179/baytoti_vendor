import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/app/session_notifier.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/usecases/application_usecases.dart';
import 'application_state.dart';

/// The family's application, which decides whether the store screens open.
///
/// App-wide: [AccountGate] around the tab shell and every pushed screen
/// reads it, and a second instance would let two of them disagree. It
/// follows [SessionNotifier] — read when a session begins, forgotten when it
/// ends — rather than any cubit.
class ApplicationCubit extends BaseCubit<ApplicationState> {
  final GetApplicationUseCase _getApplication;
  final AdvanceReviewUseCase _advanceReview;
  final SessionNotifier _sessionNotifier;

  /// Bumped by every session change, so a read that lands after sign-out
  /// (or after the next sign-in began) is dropped.
  int _generation = 0;

  ApplicationCubit(
    this._getApplication,
    this._advanceReview,
    this._sessionNotifier,
  ) : super(const ApplicationState()) {
    _sessionNotifier.addListener(_onSessionChanged);
    // A session restored before this cubit existed.
    if (_sessionNotifier.isAuthenticated) load();
  }

  void _onSessionChanged() {
    _generation++;
    if (_sessionNotifier.isAuthenticated) {
      load();
    } else {
      emit(const ApplicationState());
    }
  }

  Future<void> load() async {
    final generation = _generation;
    // Re-reads keep what is on screen; only the first shows a spinner.
    if (state.application == null) {
      emit(state.copyWith(status: ApplicationStatus.loading));
    }

    final result = await _getApplication(NoParams());
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.application == null
            ? ApplicationStatus.error
            : ApplicationStatus.loaded,
        errorMessage: failure.message,
      )),
      (application) => emit(state.copyWith(
        status: ApplicationStatus.loaded,
        application: application,
      )),
    );
  }

  /// The onboarding screen's button — see [AdvanceReviewUseCase].
  Future<void> advance() async {
    if (state.advancing) return;
    final generation = _generation;

    emit(state.copyWith(advancing: true));

    final result = await _advanceReview(NoParams());
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (application) => emit(state.copyWith(
        status: ApplicationStatus.loaded,
        application: application,
      )),
    );
  }

  @override
  Future<void> close() {
    _sessionNotifier.removeListener(_onSessionChanged);
    return super.close();
  }
}

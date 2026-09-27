import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_state.dart';

class DashboardCubit extends BaseCubit<DashboardState> {
  final GetDashboardUseCase _getDashboard;

  DashboardCubit(this._getDashboard) : super(const DashboardState());

  /// [refresh] keeps what is on screen while it reloads, and a failure then
  /// is a toast rather than an error screen.
  Future<void> load({bool refresh = false}) async {
    final keep = refresh && state.dashboard != null;
    emit(state.copyWith(
      status: keep ? DashboardStatus.refreshing : DashboardStatus.loading,
    ));

    final result = await _getDashboard(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: keep ? DashboardStatus.loaded : DashboardStatus.error,
        errorMessage: failure.message,
      )),
      (dashboard) => emit(state.copyWith(
        status: DashboardStatus.loaded,
        dashboard: dashboard,
      )),
    );
  }
}

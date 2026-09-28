import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_context_state.dart';

/// The account's location, as the store tab's location row shows it.
class LocationContextCubit extends BaseCubit<LocationContextState> {
  final GetLocationContextUseCase _getContext;

  LocationContextCubit(this._getContext) : super(const LocationContextState());

  /// Re-reads keep the location on screen; only the first shows it loading.
  Future<void> load() async {
    final shown = state.context;
    if (shown == null) {
      emit(const LocationContextState(status: LocationContextStatus.loading));
    }

    final result = await _getContext(NoParams());

    result.fold(
      (failure) => emit(LocationContextState(
        status: shown == null
            ? LocationContextStatus.error
            : LocationContextStatus.loaded,
        context: shown,
        errorMessage: failure.message,
      )),
      (context) => emit(LocationContextState(
        status: LocationContextStatus.loaded,
        context: context,
      )),
    );
  }

  /// The location the location page just saved.
  void adopt(LocationContext context) => emit(LocationContextState(
        status: LocationContextStatus.loaded,
        context: context,
      ));
}

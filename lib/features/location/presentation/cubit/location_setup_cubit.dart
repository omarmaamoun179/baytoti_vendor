import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_setup_state.dart';

/// The location page: the countries, the chosen country's governorates, and
/// the save. Starts on the account's current location when it has one.
class LocationSetupCubit extends BaseCubit<LocationSetupState> {
  final GetCountriesUseCase _getCountries;
  final GetGovernoratesUseCase _getGovernorates;
  final GetLocationContextUseCase _getContext;
  final SetManualLocationUseCase _setManual;

  LocationSetupCubit(
    this._getCountries,
    this._getGovernorates,
    this._getContext,
    this._setManual,
  ) : super(const LocationSetupState());

  /// Reads the countries and the current location together. The location
  /// only preselects the chips, so a failure to read it is said in a toast
  /// over a page that still works.
  Future<void> load() async {
    emit(const LocationSetupState());

    final countriesRead = _getCountries(NoParams());
    final contextRead = _getContext(NoParams());
    final countries = await countriesRead;
    final current = await contextRead;

    await countries.fold(
      (failure) async => emit(state.copyWith(
        status: LocationSetupStatus.failed,
        errorMessage: failure.message,
      )),
      (countries) async {
        final context = current.fold((_) => null, (context) => context);
        emit(state.copyWith(
          status: LocationSetupStatus.ready,
          countries: countries,
          errorMessage: current.fold((failure) => failure.message, (_) => null),
        ));

        final country = _find(countries, (c) => c.id == context?.countryId) ??
            (countries.length == 1 ? countries.single : null);
        if (country != null) {
          await selectCountry(country, keep: context?.governorateId);
        }
      },
    );
  }

  /// Reads [country]'s governorates. [keep] preselects one of them by id.
  Future<void> selectCountry(Country country, {String? keep}) async {
    if (country == state.country && state.governorates.isNotEmpty) return;
    emit(state.copyWith(
      country: country,
      governorate: () => null,
      governorates: const [],
      loadingGovernorates: true,
    ));

    final result = await _getGovernorates(country.id);
    // Another country was chosen while these were read.
    if (state.country != country) return;

    result.fold(
      (failure) => emit(state.copyWith(
        loadingGovernorates: false,
        errorMessage: failure.message,
      )),
      (governorates) => emit(state.copyWith(
        governorates: governorates,
        governorate: () => _find(governorates, (g) => g.id == keep),
        loadingGovernorates: false,
      )),
    );
  }

  void selectGovernorate(Governorate governorate) =>
      emit(state.copyWith(governorate: () => governorate));

  Future<void> save() async {
    final country = state.country;
    final governorate = state.governorate;
    if (!state.canSave || country == null || governorate == null) return;

    emit(state.copyWith(status: LocationSetupStatus.saving));

    final result = await _setManual(ManualLocationParams(
      country: country,
      governorate: governorate,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: LocationSetupStatus.ready,
        errorMessage: failure.message,
      )),
      (saved) => emit(state.copyWith(
        status: LocationSetupStatus.saved,
        saved: saved,
      )),
    );
  }

  static T? _find<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}

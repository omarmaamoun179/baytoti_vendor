import 'package:equatable/equatable.dart';

import '../../domain/entities/location.dart';

enum LocationSetupStatus { loading, ready, failed, saving, saved }

class LocationSetupState extends Equatable {
  final LocationSetupStatus status;
  final List<Country> countries;
  final List<Governorate> governorates;
  final Country? country;
  final Governorate? governorate;

  /// The chosen country's governorates are being read.
  final bool loadingGovernorates;

  /// What the server now has, once [LocationSetupStatus.saved].
  final LocationContext? saved;

  final String? errorMessage;

  const LocationSetupState({
    this.status = LocationSetupStatus.loading,
    this.countries = const [],
    this.governorates = const [],
    this.country,
    this.governorate,
    this.loadingGovernorates = false,
    this.saved,
    this.errorMessage,
  });

  bool get isSaving => status == LocationSetupStatus.saving;

  bool get canSave => country != null && governorate != null && !isSaving;

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again. [governorate] takes a function so it can be
  /// cleared: a new country drops the governorate chosen in the old one.
  LocationSetupState copyWith({
    LocationSetupStatus? status,
    List<Country>? countries,
    List<Governorate>? governorates,
    Country? country,
    Governorate? Function()? governorate,
    bool? loadingGovernorates,
    LocationContext? saved,
    String? errorMessage,
  }) {
    return LocationSetupState(
      status: status ?? this.status,
      countries: countries ?? this.countries,
      governorates: governorates ?? this.governorates,
      country: country ?? this.country,
      governorate: governorate == null ? this.governorate : governorate(),
      loadingGovernorates: loadingGovernorates ?? this.loadingGovernorates,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        countries,
        governorates,
        country,
        governorate,
        loadingGovernorates,
        saved,
        errorMessage,
      ];
}

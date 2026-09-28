import 'package:equatable/equatable.dart';

/// A country the platform serves (`GET /countries`).
class Country extends Equatable {
  /// The country's id, as text.
  final String id;

  /// As the server spells it, in the request's language.
  final String name;

  const Country({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// A governorate of a country (`GET /countries/{country}/governorates`).
class Governorate extends Equatable {
  final String id;
  final String name;

  const Governorate({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// The account's location on the server (`GET|POST /location/context`) —
/// a country and a governorate, or nothing yet.
///
/// A name can be missing when the answer carries only ids.
class LocationContext extends Equatable {
  final String? countryId;
  final String? countryName;
  final String? governorateId;
  final String? governorateName;

  const LocationContext({
    this.countryId,
    this.countryName,
    this.governorateId,
    this.governorateName,
  });

  static const LocationContext none = LocationContext();

  bool get isSet => countryId != null && governorateId != null;

  /// This context with the names it lacks taken from [country] and
  /// [governorate], when they are the ones it names.
  LocationContext named({Country? country, Governorate? governorate}) =>
      LocationContext(
        countryId: countryId,
        countryName: countryName ??
            (country?.id == countryId ? country?.name : null),
        governorateId: governorateId,
        governorateName: governorateName ??
            (governorate?.id == governorateId ? governorate?.name : null),
      );

  @override
  List<Object?> get props =>
      [countryId, countryName, governorateId, governorateName];
}

/// A location chosen by hand — the `manual` mode of `POST /location/context`.
class ManualLocationParams extends Equatable {
  final Country country;
  final Governorate governorate;

  const ManualLocationParams({
    required this.country,
    required this.governorate,
  });

  @override
  List<Object?> get props => [country, governorate];
}

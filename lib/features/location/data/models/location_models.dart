import '../../../../core/utils/json_read.dart';
import '../../domain/entities/location.dart';

/// Countries (`GET /countries`) and governorates
/// (`GET /countries/{country}/governorates`): `{id, name, status, …}`. One
/// switched off (`status: false`) is not offered.
List<Country> countriesFromApi(List<dynamic> rows) => [
      for (final row in asMapList(rows))
        if (asBool(row['status']) ?? true)
          if (asString(row['id']) case final id?)
            Country(id: id, name: asString(row['name']) ?? id),
    ];

List<Governorate> governoratesFromApi(List<dynamic> rows) => [
      for (final row in asMapList(rows))
        if (asBool(row['status']) ?? true)
          if (asString(row['id']) case final id?)
            Governorate(id: id, name: asString(row['name']) ?? id),
    ];

/// Reads the answer of `GET|POST /location/context`, which the spec types
/// only as "object". Guessed from the backend guide's field names (the
/// customer app reads the same):
///
/// ```json
/// {"mode": "manual",
///  "selected_country_id": 1, "selected_governorate_id": 3,
///  "resolved_country_id": null, "resolved_governorate_id": null,
///  "selected_country": {"id": 1, "name": "Egypt", "code": "EG"},
///  "selected_governorate": {"id": 3, "country_id": 1, "name": "Alexandria"}}
/// ```
///
/// `data: null` is no location yet. The chosen pair (`selected_*`) is read
/// first, then the one resolved from coordinates (`resolved_*`), then plain
/// `country_id`/`country`; the country and governorate come from the same
/// pair. The whole of it may also sit under `context`.
LocationContext locationContextFromApi(Object? data) {
  if (data is! Map) return LocationContext.none;
  final json = asMap(data);
  final source = json['context'] is Map ? asMap(json['context']) : json;

  for (final prefix in const ['selected_', 'resolved_', '']) {
    final country = asMap(source['${prefix}country']);
    final countryId =
        asString(source['${prefix}country_id']) ?? asString(country['id']);
    if (countryId == null) continue;

    final governorate = asMap(source['${prefix}governorate']);
    return LocationContext(
      countryId: countryId,
      countryName: asString(country['name']),
      governorateId: asString(source['${prefix}governorate_id']) ??
          asString(governorate['id']),
      governorateName: asString(governorate['name']),
    );
  }
  return LocationContext.none;
}

/// The body of `POST /location/context` for a location chosen by hand, per
/// the OpenAPI `UpdateLocationContextRequest`: ids go as integers, and the
/// coordinates — for `auto` — are left out.
Map<String, dynamic> manualLocationBody(ManualLocationParams params) => {
      'mode': 'manual',
      'country_id': asInt(params.country.id) ?? params.country.id,
      'governorate_id': asInt(params.governorate.id) ?? params.governorate.id,
    };

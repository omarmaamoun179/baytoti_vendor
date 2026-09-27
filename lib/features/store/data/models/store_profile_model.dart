import '../../../../core/utils/json_read.dart';
import '../../domain/entities/store_profile.dart';

/// The family's store, read from two shapes.
///
/// The fixtures answer in the design contract's `GET /vendor/store` shape,
/// read by [StoreProfileModel.fromJson]:
///
/// ```json
/// {"name": "أسرة أم عبدالله", "story": "مطبخ منزلي في حولي منذ ٢٠١٤…",
///  "area": {"id": "1", "name": "حولي"}, "areas": [ … ],
///  "cover": {…image…}, "avatar": {…image…},
///  "documents": [{"type": "civil_id", "label": "البطاقة المدنية",
///                 "state": "verified"}, …]}
/// ```
///
/// The live API's store is read by [StoreProfileModel.fromApi].
class StoreProfileModel extends StoreProfile {
  const StoreProfileModel({
    required super.name,
    super.story,
    super.area,
    super.areas,
    super.coverUrl,
    super.avatarUrl,
    super.documents,
    super.coverEditable,
  });

  factory StoreProfileModel.fromJson(Map<String, dynamic> json) {
    return StoreProfileModel(
      name: asString(json['name']) ?? '',
      story: asString(json['story']) ?? '',
      area: _areaFrom(asMap(json['area'])),
      areas: [
        for (final area in asMapList(json['areas'])) ?_areaFrom(area),
      ],
      coverUrl: asString(asMap(json['cover'])['url']),
      avatarUrl: asString(asMap(json['avatar'])['url']),
      documents: [
        for (final document in asMapList(json['documents']))
          if (asString(document['type']) case final type?)
            StoreDocument(
              type: type,
              label: asString(document['label']) ?? type,
              state: DocumentState.fromWire(asString(document['state'])),
            ),
      ],
      coverEditable: true,
    );
  }

  /// A row of `GET /vendor/stores`. The spec types it only as "object", so
  /// the names a Laravel store resource uses are read leniently:
  ///
  /// ```json
  /// {"id": 8, "name": "أسرة أم عبدالله", "slug": "…",
  ///  "description": "مطبخ منزلي…", "logo": null, "banner": null,
  ///  "phone": null, "email": null, "status": true,
  ///  "country_id": 1, "governorate_id": 3,
  ///  "governorate": {"id": 3, "name": "Alexandria"}}
  /// ```
  ///
  /// [areas] are the governorates of the store's country, read beside it.
  /// The API keeps no documents, and takes a cover only as a stored path —
  /// so none are shown, and the cover cannot be changed from here.
  factory StoreProfileModel.fromApi(
    Map<String, dynamic> json, {
    required List<StoreArea> areas,
  }) {
    final governorate = asMap(json['governorate']);
    final areaId = asString(json['governorate_id']) ??
        asString(governorate['id']);
    final area = areaId == null
        ? null
        : areas.where((area) => area.id == areaId).firstOrNull ??
            StoreArea(id: areaId, name: asString(governorate['name']) ?? '');

    return StoreProfileModel(
      name: asString(json['name']) ?? '',
      story: asString(json['description']) ?? '',
      area: area,
      areas: areas,
      coverUrl: _imageUrl(json['banner']) ?? _imageUrl(json['cover']),
      avatarUrl: _imageUrl(json['logo']),
    );
  }

  static StoreArea? _areaFrom(Map<String, dynamic> json) {
    final id = asString(json['id']);
    return id == null
        ? null
        : StoreArea(id: id, name: asString(json['name']) ?? id);
  }

  /// A bare URL, or an image object carrying one.
  static String? _imageUrl(Object? value) =>
      value is Map ? asString(value['url']) : asString(value);
}

/// A governorate of `GET /countries/{country}/governorates`:
/// `{"id": 3, "country_id": 1, "name": "Alexandria", "code": "ALX",
/// "status": true, "sort_order": 3}`. One switched off is not offered.
List<StoreArea> areasFromApi(List<dynamic> rows) => [
      for (final row in asMapList(rows))
        if (asBool(row['status']) ?? true)
          if (asString(row['id']) case final id?)
            StoreArea(id: id, name: asString(row['name']) ?? id),
    ];

/// The body of `PUT /vendor/stores/{store}`, per the OpenAPI
/// `UpdateStoreRequest` plus the location the guide says an update now
/// carries.
///
/// Only what the form edits goes out. Laravel updates from the validated
/// input, which holds just the keys sent, so the phone, email and images
/// stay as they are — and they are not echoed back, since an image URL the
/// server built from a stored path would be saved as the path. [countryId]
/// is the country whose governorates were offered; a story left empty goes
/// out as null, the spec's way to clear it.
Map<String, dynamic> updateStoreBody(
  UpdateStoreParams params, {
  required int? countryId,
}) {
  final story = params.story.trim();
  final areaId = params.areaId == null ? null : int.tryParse(params.areaId!);

  return {
    'name': params.name.trim(),
    'description': story.isEmpty ? null : story,
    if (areaId != null) ...{
      'country_id': ?countryId,
      'governorate_id': areaId,
    },
  };
}

/// The store's country: `country_id`, or a nested `country`.
int? countryIdOf(Map<String, dynamic> store) =>
    asInt(store['country_id']) ?? asInt(asMap(store['country'])['id']);

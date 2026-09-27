import '../../../../core/utils/json_read.dart';
import '../../domain/entities/store_profile.dart';

/// `GET /vendor/store`, and — a guess, the contract gives no answer for it —
/// `PATCH /vendor/store`:
///
/// ```json
/// {"name": "أسرة أم عبدالله", "story": "مطبخ منزلي في حولي منذ ٢٠١٤…",
///  "city": "حولي", "cover": {…image…}, "avatar": {…image…},
///  "documents": [{"type": "civil_id", "label": "البطاقة المدنية",
///                 "state": "verified"}, …]}
/// ```
class StoreProfileModel extends StoreProfile {
  const StoreProfileModel({
    required super.name,
    super.story,
    super.city,
    super.coverUrl,
    super.avatarUrl,
    super.documents,
  });

  factory StoreProfileModel.fromJson(Map<String, dynamic> json) {
    return StoreProfileModel(
      name: asString(json['name']) ?? '',
      story: asString(json['story']) ?? '',
      city: StoreCity.fromWire(asString(json['city'])),
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
    );
  }
}

/// The body of `PATCH /vendor/store`.
Map<String, dynamic> updateStoreBody(UpdateStoreParams params) => {
      'name': params.name.trim(),
      'story': params.story.trim(),
      'city': params.city?.wire,
      if (params.coverUploadId != null)
        'cover_upload_id': params.coverUploadId,
    };

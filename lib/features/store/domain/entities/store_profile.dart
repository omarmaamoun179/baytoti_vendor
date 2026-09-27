import 'package:equatable/equatable.dart';

/// The cities the design offers. Sent as these keys: the contract's example
/// sends `"city": "حولي"`, the city's Arabic name, and which the server
/// wants is to be checked.
enum StoreCity {
  hawalli('hawalli'),
  salmiya('salmiya'),
  jahra('jahra'),
  farwaniya('farwaniya'),
  ahmadi('ahmadi');

  const StoreCity(this.wire);

  final String wire;

  /// Reads the key, or the Arabic name the contract's example uses.
  static StoreCity? fromWire(String? value) => switch (value) {
        'hawalli' || 'حولي' => hawalli,
        'salmiya' || 'السالمية' => salmiya,
        'jahra' || 'الجهراء' => jahra,
        'farwaniya' || 'الفروانية' => farwaniya,
        'ahmadi' || 'الأحمدي' => ahmadi,
        _ => null,
      };
}

enum DocumentState {
  verified('verified'),
  inReview('in_review'),
  rejected('rejected'),
  missing('missing');

  const DocumentState(this.wire);

  final String wire;

  static DocumentState fromWire(String? value) => values.firstWhere(
        (state) => state.wire == value,
        orElse: () => inReview,
      );
}

/// A verification document — civil ID, home business licence, food safety.
class StoreDocument extends Equatable {
  final String type;

  /// Already in the app's language.
  final String label;

  final DocumentState state;

  const StoreDocument({
    required this.type,
    required this.label,
    required this.state,
  });

  @override
  List<Object?> get props => [type, label, state];
}

/// Limits on the store's details — the app's own until the API states its
/// rules; kept on the domain so the form and the request agree.
class StoreRules {
  StoreRules._();

  static const int nameMinLength = 3;
  static const int nameMaxLength = 60;
  static const int storyMaxLength = 500;
}

/// `GET /vendor/store` — what the customer sees on the family's page.
class StoreProfile extends Equatable {
  final String name;
  final String story;
  final StoreCity? city;
  final String? coverUrl;
  final String? avatarUrl;
  final List<StoreDocument> documents;

  const StoreProfile({
    required this.name,
    this.story = '',
    this.city,
    this.coverUrl,
    this.avatarUrl,
    this.documents = const [],
  });

  @override
  List<Object?> get props =>
      [name, story, city, coverUrl, avatarUrl, documents];
}

/// `PATCH /vendor/store` — `{name, story, city, cover_upload_id,
/// avatar_upload_id}`. A null upload id leaves that image as it is.
class UpdateStoreParams extends Equatable {
  final String name;
  final String story;
  final StoreCity? city;
  final String? coverUploadId;

  /// Where the new cover is shown from — the upload's URL. Not sent: the
  /// request names the cover by [coverUploadId] alone.
  final String? coverUrl;

  const UpdateStoreParams({
    required this.name,
    required this.story,
    this.city,
    this.coverUploadId,
    this.coverUrl,
  });

  @override
  List<Object?> get props => [name, story, city, coverUploadId, coverUrl];
}

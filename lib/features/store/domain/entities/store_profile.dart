import 'package:equatable/equatable.dart';

/// Where a store trades — on the live API a governorate of the store's
/// country (`GET /countries/{country}/governorates`), which is what scopes
/// the customers who see its food. The fixtures offer the design's five
/// cities.
class StoreArea extends Equatable {
  /// The governorate's id, as text.
  final String id;

  /// Already in the app's language, or as the server spells it.
  final String name;

  const StoreArea({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
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

/// Limits on the store's details, kept on the domain so the form and the
/// request agree. Tighter than the API's `UpdateStoreRequest` (a name of
/// 2–150, a description up to 5000) — the design's card holds no more.
class StoreRules {
  StoreRules._();

  static const int nameMinLength = 3;
  static const int nameMaxLength = 60;
  static const int storyMaxLength = 500;
}

/// The family's store — what the customer sees on the family's page.
class StoreProfile extends Equatable {
  final String name;
  final String story;

  /// Where it trades; null until one is chosen.
  final StoreArea? area;

  /// What [area] may be — the chips the store tab offers.
  final List<StoreArea> areas;

  final String? coverUrl;
  final String? avatarUrl;
  final List<StoreDocument> documents;

  /// Whether a new cover can be saved. The live API takes the cover only as
  /// a stored path and offers no upload, so there it cannot.
  final bool coverEditable;

  const StoreProfile({
    required this.name,
    this.story = '',
    this.area,
    this.areas = const [],
    this.coverUrl,
    this.avatarUrl,
    this.documents = const [],
    this.coverEditable = false,
  });

  @override
  List<Object?> get props => [
        name,
        story,
        area,
        areas,
        coverUrl,
        avatarUrl,
        documents,
        coverEditable,
      ];
}

/// What the store tab saves. A null [areaId] leaves the area as it is, and
/// a null upload id leaves the cover.
class UpdateStoreParams extends Equatable {
  final String name;
  final String story;
  final String? areaId;
  final String? coverUploadId;

  /// Where the new cover is shown from — the upload's URL. Not sent: the
  /// request names the cover by [coverUploadId] alone.
  final String? coverUrl;

  const UpdateStoreParams({
    required this.name,
    required this.story,
    this.areaId,
    this.coverUploadId,
    this.coverUrl,
  });

  @override
  List<Object?> get props => [name, story, areaId, coverUploadId, coverUrl];
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/mock/mock_session_token.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/store_profile.dart';
import '../models/store_profile_model.dart';
import 'store_data_source.dart';

class _StoreRecord {
  Localized name;
  Localized story;
  String? areaId;
  String? coverUrl;

  _StoreRecord({
    required this.name,
    required this.story,
    this.areaId,
  });
}

/// The store profile on fixtures, one per account ([MockSessionToken]): the
/// fixture family's — the design's name, story and Hawalli — or, for a
/// family that just signed up, its own name and nothing else yet. The
/// documents are the design's: two verified, food safety in review. The
/// areas are the design's five cities.
class StoreMockDataSource implements StoreDataSource {
  static const List<(String, Localized)> _areas = [
    ('1', Localized('حولي', 'Hawalli')),
    ('2', Localized('السالمية', 'Salmiya')),
    ('3', Localized('الجهراء', 'Jahra')),
    ('4', Localized('الفروانية', 'Farwaniya')),
    ('5', Localized('الأحمدي', 'Ahmadi')),
  ];

  static const List<(String, Localized, DocumentState)> _documents = [
    (
      'civil_id',
      Localized('البطاقة المدنية', 'Civil ID'),
      DocumentState.verified,
    ),
    (
      'home_licence',
      Localized('رخصة العمل المنزلي', 'Home business licence'),
      DocumentState.verified,
    ),
    (
      'food_safety',
      Localized('شهادة سلامة غذائية', 'Food safety certificate'),
      DocumentState.inReview,
    ),
  ];

  final TokenStore _tokenStore;
  final MockLocale _locale;
  final Map<String, _StoreRecord> _stores = {};

  StoreMockDataSource(this._tokenStore, this._locale);

  @override
  Future<Either<Failure, StoreProfileModel>> getStore() => guardedRequest(
        'StoreMockDataSource.getStore',
        () async {
          await Future<void>.delayed(mockLatency);
          return _answer(await _store());
        },
        fallbackMessage: 'store_failed',
      );

  @override
  Future<Either<Failure, StoreProfileModel>> updateStore(
    UpdateStoreParams params,
  ) =>
      guardedRequest(
        'StoreMockDataSource.updateStore',
        () async {
          await Future<void>.delayed(mockLatency * 2);

          final name = params.name.trim();
          final story = params.story.trim();
          final store = await _store()
            // The family's own words read the same in either language.
            ..name = Localized(name, name)
            ..story = Localized(story, story);
          if (params.areaId != null) store.areaId = params.areaId;
          if (params.coverUploadId != null) store.coverUrl = params.coverUrl;

          return _answer(store);
        },
        fallbackMessage: 'store_save_failed',
      );

  Future<_StoreRecord> _store() async {
    final account = MockSessionToken.decode(
      (await _tokenStore.read())?.accessToken,
    );
    // What the server says to a token it did not issue.
    if (account == null) throw const SessionExpiredException();

    return _stores.putIfAbsent(account.phoneDigits, () {
      final familyName = account.familyName;
      if (familyName != null) {
        return _StoreRecord(
          name: Localized(familyName, familyName),
          story: const Localized('', ''),
        );
      }
      return _StoreRecord(
        name: const Localized('أسرة أم عبدالله', 'Umm Abdullah Family'),
        story: const Localized(
          'مطبخ منزلي في حولي منذ ٢٠١٤. نصنع الحلويات الكويتية بوصفات العائلة، '
              'ونخبز يومياً بكميات محدودة.',
          'A home kitchen in Hawalli since 2014. Kuwaiti sweets from family '
              'recipes, baked daily in small batches.',
        ),
        areaId: '1',
      );
    });
  }

  Future<StoreProfileModel> _answer(_StoreRecord store) async {
    final ar = await _locale.isArabic();

    return StoreProfileModel.fromJson({
      'name': store.name.pick(ar),
      'story': store.story.pick(ar),
      'area': _areaJson(store.areaId, ar),
      'areas': [for (final (id, _) in _areas) _areaJson(id, ar)],
      'cover': store.coverUrl == null ? null : {'url': store.coverUrl},
      'avatar': null,
      'documents': [
        for (final (type, label, state) in _documents)
          {'type': type, 'label': label.pick(ar), 'state': state.wire},
      ],
    });
  }

  static Map<String, dynamic>? _areaJson(String? id, bool ar) {
    for (final (areaId, name) in _areas) {
      if (areaId == id) return {'id': areaId, 'name': name.pick(ar)};
    }
    return null;
  }
}

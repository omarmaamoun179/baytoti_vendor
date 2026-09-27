import 'package:baytoti_vendor/features/store/data/models/store_profile_model.dart';
import 'package:baytoti_vendor/features/store/domain/entities/store_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const areas = [
    StoreArea(id: '1', name: 'Cairo'),
    StoreArea(id: '3', name: 'Alexandria'),
  ];

  group('the live store', () {
    test('reads its area by governorate id among those offered', () {
      final store = StoreProfileModel.fromApi({
        'id': 8,
        'name': 'أسرة أم عبدالله',
        'description': 'مطبخ منزلي',
        'country_id': 1,
        'governorate_id': 3,
        'banner': 'https://example.com/cover.jpg',
      }, areas: areas);

      expect(store.name, 'أسرة أم عبدالله');
      expect(store.story, 'مطبخ منزلي');
      expect(store.area, areas[1]);
      expect(store.coverUrl, 'https://example.com/cover.jpg');
      // The API takes no upload, so the cover is not offered for change.
      expect(store.coverEditable, isFalse);
      expect(store.documents, isEmpty);
    });

    test('keeps a governorate the list did not offer, by its nested name', () {
      final store = StoreProfileModel.fromApi({
        'name': 'x',
        'governorate': {'id': 9, 'name': 'Giza'},
      }, areas: areas);

      expect(store.area, const StoreArea(id: '9', name: 'Giza'));
    });

    test('switched-off governorates are not offered', () {
      final offered = areasFromApi([
        {'id': 1, 'name': 'Cairo', 'status': true},
        {'id': 2, 'name': 'Giza', 'status': false},
      ]);

      expect(offered, [const StoreArea(id: '1', name: 'Cairo')]);
    });
  });

  group('a store save', () {
    test('sends the location only when an area was chosen', () {
      final body = updateStoreBody(
        const UpdateStoreParams(name: ' Kitchen ', story: '', areaId: '3'),
        countryId: 1,
      );

      expect(body, {
        'name': 'Kitchen',
        'description': null,
        'country_id': 1,
        'governorate_id': 3,
      });
    });

    test('leaves the location alone without one', () {
      final body = updateStoreBody(
        const UpdateStoreParams(name: 'Kitchen', story: 'Since 2014'),
        countryId: 1,
      );

      expect(body, {'name': 'Kitchen', 'description': 'Since 2014'});
    });
  });
}

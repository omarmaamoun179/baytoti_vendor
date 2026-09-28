import 'package:baytoti_vendor/core/domain/failure.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/features/location/data/datasources/location_data_source.dart';
import 'package:baytoti_vendor/features/location/data/datasources/location_mock_data_source.dart';
import 'package:baytoti_vendor/features/location/data/models/location_models.dart';
import 'package:baytoti_vendor/features/location/data/repositories/location_repository_impl.dart';
import 'package:baytoti_vendor/features/location/domain/entities/location.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// A server that names the location by id alone.
class _IdsOnlySource implements LocationDataSource {
  @override
  Future<Either<Failure, List<Country>>> getCountries() async =>
      const Right([Country(id: '1', name: 'Egypt')]);

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) async =>
      const Right([Governorate(id: '3', name: 'Alexandria')]);

  @override
  Future<Either<Failure, LocationContext>> getContext() async =>
      Right(locationContextFromApi({
        'selected_country_id': 1,
        'selected_governorate_id': 3,
      }));

  @override
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  ) async =>
      Right(locationContextFromApi({'message': 'saved'}));
}

void main() {
  const egypt = Country(id: '1', name: 'Egypt');
  const alexandria = Governorate(id: '3', name: 'Alexandria');

  group('the live location', () {
    test('reads the chosen pair with its names', () {
      final context = locationContextFromApi({
        'mode': 'manual',
        'selected_country_id': 1,
        'selected_governorate_id': 3,
        'resolved_country_id': null,
        'selected_country': {'id': 1, 'name': 'Egypt', 'code': 'EG'},
        'selected_governorate': {'id': 3, 'country_id': 1, 'name': 'Alexandria'},
      });

      expect(
        context,
        const LocationContext(
          countryId: '1',
          countryName: 'Egypt',
          governorateId: '3',
          governorateName: 'Alexandria',
        ),
      );
    });

    test('falls back to the pair resolved from coordinates', () {
      final context = locationContextFromApi({
        'mode': 'auto',
        'selected_country_id': null,
        'resolved_country': {'id': 2, 'name': 'Kuwait'},
        'resolved_governorate_id': 5,
      });

      expect(context.countryId, '2');
      expect(context.countryName, 'Kuwait');
      expect(context.governorateId, '5');
    });

    test('no data is no location', () {
      expect(locationContextFromApi(null), LocationContext.none);
      expect(locationContextFromApi({'mode': 'manual'}).isSet, isFalse);
    });

    test('a manual save sends integer ids and no coordinates', () {
      expect(
        manualLocationBody(
          const ManualLocationParams(country: egypt, governorate: alexandria),
        ),
        {'mode': 'manual', 'country_id': 1, 'governorate_id': 3},
      );
    });

    test('switched-off places are not offered', () {
      expect(
        countriesFromApi([
          {'id': 1, 'name': 'Egypt', 'status': true},
          {'id': 2, 'name': 'Kuwait', 'status': false},
        ]),
        [egypt],
      );
    });
  });

  group('the location repository', () {
    final repository = LocationRepositoryImpl(_IdsOnlySource());

    test('names a location the server gave by id alone', () async {
      final context = (await repository.getContext())
          .getOrElse(() => throw 'failed');

      expect(context.countryName, 'Egypt');
      expect(context.governorateName, 'Alexandria');
    });

    test('reads a save that answers without it as the one sent', () async {
      final saved = (await repository.setManual(
        const ManualLocationParams(country: egypt, governorate: alexandria),
      ))
          .getOrElse(() => throw 'failed');

      expect(
        saved,
        const LocationContext(
          countryId: '1',
          countryName: 'Egypt',
          governorateId: '3',
          governorateName: 'Alexandria',
        ),
      );
    });
  });

  group('the location fixtures', () {
    LocationMockDataSource source(MemoryTokenStore tokens) =>
        LocationMockDataSource(tokens, MockLocale(FakeCacheService()));

    test('the fixture family starts in Hawalli, a new one nowhere', () async {
      final fixture = (await source(MemoryTokenStore.signedIn()).getContext())
          .getOrElse(() => throw 'failed');
      final fresh = (await source(MemoryTokenStore.signedIn(
        isNewFamily: true,
        familyName: 'مطبخ سارة',
      )).getContext())
          .getOrElse(() => throw 'failed');

      expect(fixture.governorateId, '2');
      expect(fresh.isSet, isFalse);
    });

    test('a save lasts the run', () async {
      final fixtures = source(MemoryTokenStore.signedIn());
      await fixtures.setManual(const ManualLocationParams(
        country: Country(id: '2', name: 'مصر'),
        governorate: Governorate(id: '9', name: 'الإسكندرية'),
      ));

      final context =
          (await fixtures.getContext()).getOrElse(() => throw 'failed');
      expect(context.countryId, '2');
      expect(context.governorateId, '9');
    });

    test('refuses a governorate outside the country, as the server does',
        () async {
      final result = await source(MemoryTokenStore.signedIn()).setManual(
        const ManualLocationParams(
          country: Country(id: '1', name: 'الكويت'),
          governorate: Governorate(id: '9', name: 'الإسكندرية'),
        ),
      );

      final failure = result.fold((failure) => failure, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).fieldErrors,
        contains('governorate_id'),
      );
    });

    test('asks a token it did not issue to sign in again', () async {
      final result = await source(MemoryTokenStore()).getContext();
      expect(result.isLeft(), isTrue);
    });
  });
}

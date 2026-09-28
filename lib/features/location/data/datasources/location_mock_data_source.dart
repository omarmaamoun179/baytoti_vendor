import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/mock/mock_session_token.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/location.dart';
import '../models/location_models.dart';
import 'location_data_source.dart';

/// The account's location on fixtures, one per account
/// ([MockSessionToken]) for the run: the fixture family starts in Hawalli,
/// Kuwait; a family that just signed up has none. There is no design
/// contract for location, so the fixtures answer in the live API's shape
/// and are read by the same functions.
class LocationMockDataSource implements LocationDataSource {
  static const Map<String, Localized> _countries = {
    '1': Localized('الكويت', 'Kuwait'),
    '2': Localized('مصر', 'Egypt'),
  };

  static const Map<String, Map<String, Localized>> _governorates = {
    '1': {
      '1': Localized('العاصمة', 'Capital'),
      '2': Localized('حولي', 'Hawalli'),
      '3': Localized('الفروانية', 'Farwaniya'),
      '4': Localized('الأحمدي', 'Ahmadi'),
      '5': Localized('الجهراء', 'Jahra'),
      '6': Localized('مبارك الكبير', 'Mubarak Al-Kabeer'),
    },
    '2': {
      '7': Localized('القاهرة', 'Cairo'),
      '8': Localized('الجيزة', 'Giza'),
      '9': Localized('الإسكندرية', 'Alexandria'),
    },
  };

  final TokenStore _tokenStore;
  final MockLocale _locale;

  /// `(country id, governorate id)` by account phone.
  final Map<String, (String, String)?> _contexts = {};

  LocationMockDataSource(this._tokenStore, this._locale);

  @override
  Future<Either<Failure, List<Country>>> getCountries() => guardedRequest(
        'LocationMockDataSource.getCountries',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();
          return countriesFromApi([
            for (final MapEntry(key: id, value: name) in _countries.entries)
              {'id': int.parse(id), 'name': name.pick(ar), 'status': true},
          ]);
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) =>
      guardedRequest(
        'LocationMockDataSource.getGovernorates',
        () async {
          await Future<void>.delayed(mockLatency);
          final governorates = _governorates[countryId];
          if (governorates == null) {
            throw const RequestException('location_failed', statusCode: 404);
          }
          final ar = await _locale.isArabic();
          return governoratesFromApi([
            for (final MapEntry(key: id, value: name) in governorates.entries)
              {'id': int.parse(id), 'name': name.pick(ar), 'status': true},
          ]);
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> getContext() => guardedRequest(
        'LocationMockDataSource.getContext',
        () async {
          await Future<void>.delayed(mockLatency);
          final account = await _account();
          final context = _contexts.putIfAbsent(
            account.phoneDigits,
            () => account.familyName == null ? ('1', '2') : null,
          );
          return locationContextFromApi(await _answer(context));
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  ) =>
      guardedRequest(
        'LocationMockDataSource.setManual',
        () async {
          await Future<void>.delayed(mockLatency * 2);
          final account = await _account();

          final countryId = params.country.id;
          final governorateId = params.governorate.id;
          // What the server says to a governorate outside the country.
          if (_governorates[countryId]?[governorateId] == null) {
            const message = 'location_governorate_mismatch';
            throw const RequestException(
              message,
              statusCode: 422,
              errors: {
                'governorate_id': [message],
              },
            );
          }

          final context = (countryId, governorateId);
          _contexts[account.phoneDigits] = context;
          return locationContextFromApi(await _answer(context));
        },
        fallbackMessage: 'location_save_failed',
      );

  Future<MockSessionToken> _account() async {
    final account = MockSessionToken.decode(
      (await _tokenStore.read())?.accessToken,
    );
    // What the server says to a token it did not issue.
    if (account == null) throw const SessionExpiredException();
    return account;
  }

  Future<Map<String, dynamic>?> _answer((String, String)? context) async {
    if (context == null) return null;
    final (countryId, governorateId) = context;
    final ar = await _locale.isArabic();

    return {
      'mode': 'manual',
      'selected_country_id': int.parse(countryId),
      'selected_governorate_id': int.parse(governorateId),
      'selected_country': {
        'id': int.parse(countryId),
        'name': _countries[countryId]!.pick(ar),
      },
      'selected_governorate': {
        'id': int.parse(governorateId),
        'name': _governorates[countryId]![governorateId]!.pick(ar),
      },
    };
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/location.dart';
import '../models/location_models.dart';
import 'location_data_source.dart';

/// The account's location on the live API.
class LocationRemoteDataSource implements LocationDataSource {
  final NetworkService _networkService;

  /// Read once: countries and governorates change with the platform, not
  /// with a session.
  List<Country>? _countries;
  final Map<String, List<Governorate>> _governorates = {};

  LocationRemoteDataSource(this._networkService);

  @override
  Future<Either<Failure, List<Country>>> getCountries() => guardedRequest(
        'LocationRemoteDataSource.getCountries',
        () async {
          final known = _countries;
          if (known != null) return known;

          final envelope = checkedResponse(
            await _networkService.get(
              ApiEndPoint.countries,
              skipAuthRefresh: true,
            ),
          );
          return _countries = countriesFromApi(envelope.dataList);
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) =>
      guardedRequest(
        'LocationRemoteDataSource.getGovernorates',
        () async {
          final known = _governorates[countryId];
          if (known != null) return known;

          final envelope = checkedResponse(
            await _networkService.get(
              ApiEndPoint.governorates(countryId),
              skipAuthRefresh: true,
            ),
          );
          return _governorates[countryId] =
              governoratesFromApi(envelope.dataList);
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> getContext() => guardedRequest(
        'LocationRemoteDataSource.getContext',
        () async {
          try {
            final response =
                await _networkService.get(ApiEndPoint.locationContext);
            return locationContextFromApi(checkedResponse(response).data);
          } on RequestException catch (e) {
            // No location chosen yet may be answered as "not found".
            if (e.statusCode == 404) return LocationContext.none;
            rethrow;
          }
        },
        fallbackMessage: 'location_failed',
      );

  @override
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  ) =>
      guardedRequest(
        'LocationRemoteDataSource.setManual',
        () async {
          final response = await _networkService.post(
            ApiEndPoint.locationContext,
            data: manualLocationBody(params),
          );
          return locationContextFromApi(checkedResponse(response).data);
        },
        fallbackMessage: 'location_save_failed',
      );
}

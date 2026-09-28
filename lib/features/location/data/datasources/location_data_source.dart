import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/location.dart';

/// The account's location and the places it may be. [LocationRemoteDataSource]
/// reads the live API (`GET /countries`, `/countries/{id}/governorates`,
/// `GET|POST /location/context`); [LocationMockDataSource] answers from
/// fixtures.
abstract class LocationDataSource {
  /// The countries the platform serves, switched-off ones left out.
  Future<Either<Failure, List<Country>>> getCountries();

  Future<Either<Failure, List<Governorate>>> getGovernorates(String countryId);

  /// [LocationContext.none] when the account has none yet.
  Future<Either<Failure, LocationContext>> getContext();

  /// Answers with the location as the server now has it.
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  );
}

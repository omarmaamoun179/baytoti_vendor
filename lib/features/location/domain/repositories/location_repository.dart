import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/location.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<Country>>> getCountries();

  Future<Either<Failure, List<Governorate>>> getGovernorates(String countryId);

  /// The account's location, with the names filled in when the answer
  /// carried only ids. [LocationContext.none] when none is set.
  Future<Either<Failure, LocationContext>> getContext();

  /// Saves [params] and answers with the location as it now stands.
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  );
}

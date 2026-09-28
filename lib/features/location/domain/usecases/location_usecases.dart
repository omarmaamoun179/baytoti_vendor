import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetCountriesUseCase
    implements UseCase<Either<Failure, List<Country>>, NoParams> {
  final LocationRepository _repository;

  GetCountriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Country>>> call(NoParams params) =>
      _repository.getCountries();
}

/// The governorates of the country whose id is given.
class GetGovernoratesUseCase
    implements UseCase<Either<Failure, List<Governorate>>, String> {
  final LocationRepository _repository;

  GetGovernoratesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Governorate>>> call(String countryId) =>
      _repository.getGovernorates(countryId);
}

class GetLocationContextUseCase
    implements UseCase<Either<Failure, LocationContext>, NoParams> {
  final LocationRepository _repository;

  GetLocationContextUseCase(this._repository);

  @override
  Future<Either<Failure, LocationContext>> call(NoParams params) =>
      _repository.getContext();
}

class SetManualLocationUseCase
    implements UseCase<Either<Failure, LocationContext>, ManualLocationParams> {
  final LocationRepository _repository;

  SetManualLocationUseCase(this._repository);

  @override
  Future<Either<Failure, LocationContext>> call(ManualLocationParams params) =>
      _repository.setManual(params);
}

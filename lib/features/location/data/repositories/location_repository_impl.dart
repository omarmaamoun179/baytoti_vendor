import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _dataSource;

  LocationRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Country>>> getCountries() =>
      _dataSource.getCountries();

  @override
  Future<Either<Failure, List<Governorate>>> getGovernorates(
    String countryId,
  ) =>
      _dataSource.getGovernorates(countryId);

  /// An answer that names its places by id alone is named from the country
  /// and governorate lists, which the source keeps once read. A list that
  /// cannot be read leaves the name out rather than failing a location the
  /// server did answer.
  @override
  Future<Either<Failure, LocationContext>> getContext() async {
    final result = await _dataSource.getContext();

    return result.fold<Future<Either<Failure, LocationContext>>>(
      (failure) async => Left(failure),
      (context) async {
        final countryId = context.countryId;
        final governorateId = context.governorateId;
        if (countryId == null) return Right(context);

        Country? country;
        if (context.countryName == null) {
          final countries = await _dataSource.getCountries();
          country = countries.fold(
            (_) => null,
            (all) => _firstWhere(all, (c) => c.id == countryId),
          );
        }

        Governorate? governorate;
        if (context.governorateName == null && governorateId != null) {
          final governorates = await _dataSource.getGovernorates(countryId);
          governorate = governorates.fold(
            (_) => null,
            (all) => _firstWhere(all, (g) => g.id == governorateId),
          );
        }

        return Right(context.named(country: country, governorate: governorate));
      },
    );
  }

  /// An answer without the location in it is read as the one sent.
  @override
  Future<Either<Failure, LocationContext>> setManual(
    ManualLocationParams params,
  ) async {
    final result = await _dataSource.setManual(params);

    return result.map((answered) {
      final saved = answered.isSet
          ? answered
          : LocationContext(
              countryId: params.country.id,
              governorateId: params.governorate.id,
            );
      return saved.named(
        country: params.country,
        governorate: params.governorate,
      );
    });
  }

  static T? _firstWhere<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}

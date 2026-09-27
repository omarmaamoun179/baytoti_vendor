import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offers_repository.dart';
import '../datasources/offers_data_source.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersDataSource _dataSource;

  OffersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, OffersOverview>> getOffers() =>
      _dataSource.getOffers();

  @override
  Future<Either<Failure, Offer>> createOffer(CreateOfferParams params) =>
      _dataSource.createOffer(params);

  @override
  Future<Either<Failure, Unit>> deleteOffer(String id) =>
      _dataSource.deleteOffer(id);
}

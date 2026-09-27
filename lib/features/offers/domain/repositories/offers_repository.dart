import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/offer.dart';

abstract class OffersRepository {
  Future<Either<Failure, OffersOverview>> getOffers();

  Future<Either<Failure, Offer>> createOffer(CreateOfferParams params);

  Future<Either<Failure, Unit>> deleteOffer(String id);
}

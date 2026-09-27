import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/offer.dart';
import '../models/offer_models.dart';

/// The vendor offers endpoints. Only fixtures implement it today.
abstract class OffersDataSource {
  /// `GET /vendor/offers`.
  Future<Either<Failure, OffersOverviewModel>> getOffers();

  /// `POST /vendor/offers` with [createOfferBody].
  Future<Either<Failure, OfferModel>> createOffer(CreateOfferParams params);

  /// `DELETE /vendor/offers/{id}`.
  Future<Either<Failure, Unit>> deleteOffer(String id);
}

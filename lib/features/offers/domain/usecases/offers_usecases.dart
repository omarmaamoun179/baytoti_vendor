import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

class GetOffersUseCase
    implements UseCase<Either<Failure, OffersOverview>, NoParams> {
  final OffersRepository _repository;

  GetOffersUseCase(this._repository);

  @override
  Future<Either<Failure, OffersOverview>> call(NoParams params) =>
      _repository.getOffers();
}

class CreateOfferUseCase
    implements UseCase<Either<Failure, Offer>, CreateOfferParams> {
  final OffersRepository _repository;

  CreateOfferUseCase(this._repository);

  @override
  Future<Either<Failure, Offer>> call(CreateOfferParams params) =>
      _repository.createOffer(params);
}

class DeleteOfferUseCase implements UseCase<Either<Failure, Unit>, String> {
  final OffersRepository _repository;

  DeleteOfferUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => _repository.deleteOffer(id);
}

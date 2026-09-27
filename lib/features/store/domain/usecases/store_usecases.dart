import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/store_profile.dart';
import '../repositories/store_repository.dart';

class GetStoreUseCase
    implements UseCase<Either<Failure, StoreProfile>, NoParams> {
  final StoreRepository _repository;

  GetStoreUseCase(this._repository);

  @override
  Future<Either<Failure, StoreProfile>> call(NoParams params) =>
      _repository.getStore();
}

class UpdateStoreUseCase
    implements UseCase<Either<Failure, StoreProfile>, UpdateStoreParams> {
  final StoreRepository _repository;

  UpdateStoreUseCase(this._repository);

  @override
  Future<Either<Failure, StoreProfile>> call(UpdateStoreParams params) =>
      _repository.updateStore(params);
}

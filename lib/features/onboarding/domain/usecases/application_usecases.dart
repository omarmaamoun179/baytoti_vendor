import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/vendor_application.dart';
import '../repositories/application_repository.dart';

class GetApplicationUseCase
    implements UseCase<Either<Failure, VendorApplication>, NoParams> {
  final ApplicationRepository _repository;

  GetApplicationUseCase(this._repository);

  @override
  Future<Either<Failure, VendorApplication>> call(NoParams params) =>
      _repository.getApplication();
}

class AdvanceReviewUseCase
    implements UseCase<Either<Failure, VendorApplication>, NoParams> {
  final ApplicationRepository _repository;

  AdvanceReviewUseCase(this._repository);

  @override
  Future<Either<Failure, VendorApplication>> call(NoParams params) =>
      _repository.advanceReview();
}

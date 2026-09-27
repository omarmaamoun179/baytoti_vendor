import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/vendor_dashboard.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardUseCase
    implements UseCase<Either<Failure, VendorDashboard>, NoParams> {
  final DashboardRepository _repository;

  GetDashboardUseCase(this._repository);

  @override
  Future<Either<Failure, VendorDashboard>> call(NoParams params) =>
      _repository.getDashboard();
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/vendor_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../datasources/application_data_source.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final ApplicationDataSource _dataSource;

  ApplicationRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, VendorApplication>> getApplication() =>
      _dataSource.getApplication();

  @override
  Future<Either<Failure, VendorApplication>> advanceReview() =>
      _dataSource.advanceReview();
}

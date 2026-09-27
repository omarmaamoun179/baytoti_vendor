import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_data_source.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreDataSource _dataSource;

  StoreRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, StoreProfile>> getStore() => _dataSource.getStore();

  @override
  Future<Either<Failure, StoreProfile>> updateStore(UpdateStoreParams params) =>
      _dataSource.updateStore(params);
}

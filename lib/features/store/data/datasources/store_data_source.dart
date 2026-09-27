import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/store_profile.dart';
import '../models/store_profile_model.dart';

/// The vendor store endpoints. Only fixtures implement it today.
abstract class StoreDataSource {
  /// `GET /vendor/store`.
  Future<Either<Failure, StoreProfileModel>> getStore();

  /// `PATCH /vendor/store` with [updateStoreBody].
  Future<Either<Failure, StoreProfileModel>> updateStore(
    UpdateStoreParams params,
  );
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/store_profile.dart';
import '../models/store_profile_model.dart';

/// The family's store. [StoreRemoteDataSource] reads the live API
/// (`GET /vendor/stores`, `PUT /vendor/stores/{store}`);
/// [StoreMockDataSource] answers from fixtures.
abstract class StoreDataSource {
  /// The store, with the areas it may trade in.
  Future<Either<Failure, StoreProfileModel>> getStore();

  /// Saves the details and answers with the store as the server now has it.
  Future<Either<Failure, StoreProfileModel>> updateStore(
    UpdateStoreParams params,
  );
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/store_profile.dart';

abstract class StoreRepository {
  Future<Either<Failure, StoreProfile>> getStore();

  /// Answers with the store as the server now has it.
  Future<Either<Failure, StoreProfile>> updateStore(UpdateStoreParams params);
}

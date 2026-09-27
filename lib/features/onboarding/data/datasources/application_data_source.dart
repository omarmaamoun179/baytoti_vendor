import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/vendor_application_model.dart';

/// Where the family's review stands. [ApplicationRemoteDataSource] reads it
/// from `GET /vendor/profile`; [ApplicationMockDataSource] plays the back
/// office on fixtures.
abstract class ApplicationDataSource {
  /// The review, with the approval path.
  Future<Either<Failure, VendorApplicationModel>> getApplication();

  /// Fixtures: the back office moves the review one step. The remote source
  /// has no call for this — approval is not the vendor's to make — and
  /// reads the review again.
  Future<Either<Failure, VendorApplicationModel>> advanceReview();
}

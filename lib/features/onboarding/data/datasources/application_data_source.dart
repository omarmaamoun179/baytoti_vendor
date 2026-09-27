import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/vendor_application_model.dart';

/// The onboarding endpoints of the API contract. Only fixtures implement it
/// today ([ApplicationMockDataSource]).
abstract class ApplicationDataSource {
  /// `GET /vendor/application`.
  Future<Either<Failure, VendorApplicationModel>> getApplication();

  /// Fixtures: the back office moves the review one step. A remote source
  /// has no call for this — approval is not the vendor's to make — and
  /// should answer with `GET /vendor/application` again.
  Future<Either<Failure, VendorApplicationModel>> advanceReview();
}

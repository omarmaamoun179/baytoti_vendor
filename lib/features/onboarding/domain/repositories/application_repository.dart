import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/vendor_application.dart';

abstract class ApplicationRepository {
  Future<Either<Failure, VendorApplication>> getApplication();

  /// The onboarding button: on fixtures it moves the review one step, as
  /// the back office would; against the API — where approval is the back
  /// office's alone — it reads the application again.
  Future<Either<Failure, VendorApplication>> advanceReview();
}

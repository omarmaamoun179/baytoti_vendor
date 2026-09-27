import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/vendor_dashboard.dart';

abstract class DashboardRepository {
  Future<Either<Failure, VendorDashboard>> getDashboard();
}

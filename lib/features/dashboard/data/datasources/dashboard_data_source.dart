import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/vendor_dashboard_model.dart';

/// `GET /vendor/dashboard`. Only fixtures implement it today.
abstract class DashboardDataSource {
  Future<Either<Failure, VendorDashboardModel>> getDashboard();
}

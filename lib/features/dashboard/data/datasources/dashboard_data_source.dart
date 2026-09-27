import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/vendor_dashboard_model.dart';

/// The dashboard in one read. [DashboardRemoteDataSource] builds it from
/// `GET /vendor/home`; [DashboardMockDataSource] from the fixtures the
/// orders and products tabs share.
abstract class DashboardDataSource {
  Future<Either<Failure, VendorDashboardModel>> getDashboard();
}

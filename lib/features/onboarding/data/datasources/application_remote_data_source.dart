import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../models/vendor_application_model.dart';
import 'application_data_source.dart';

/// The family's review on the live API: `GET /vendor/profile`, whose
/// `status` says where it stands.
class ApplicationRemoteDataSource implements ApplicationDataSource {
  final NetworkService _networkService;

  ApplicationRemoteDataSource(this._networkService);

  @override
  Future<Either<Failure, VendorApplicationModel>> getApplication() =>
      guardedRequest(
        'ApplicationRemoteDataSource.getApplication',
        () async {
          final response = await _networkService.get(ApiEndPoint.vendorProfile);
          return VendorApplicationModel.fromProfile(
            checkedResponse(response).dataMap,
          );
        },
        fallbackMessage: 'application_failed',
      );

  /// Approval is the platform team's alone, so "Check status" reads the
  /// profile again rather than asking for anything.
  @override
  Future<Either<Failure, VendorApplicationModel>> advanceReview() =>
      getApplication();
}

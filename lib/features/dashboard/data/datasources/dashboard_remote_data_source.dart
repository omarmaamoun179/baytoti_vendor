import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json_read.dart';
import '../../../orders/data/models/order_models.dart';
import '../models/vendor_dashboard_model.dart';
import 'dashboard_data_source.dart';

/// The dashboard on the live API: `GET /vendor/home` for the day and for
/// the week, and the first page of `GET /vendor/orders` when the day's
/// answer leaves out the orders ([VendorDashboardModel.needsOrders]).
class DashboardRemoteDataSource implements DashboardDataSource {
  final NetworkService _networkService;

  DashboardRemoteDataSource(this._networkService);

  @override
  Future<Either<Failure, VendorDashboardModel>> getDashboard() =>
      guardedRequest(
        'DashboardRemoteDataSource.getDashboard',
        () async {
          final answers = await Future.wait([
            _networkService.get(
              ApiEndPoint.vendorHome,
              queryParameters: {'period': 'today'},
            ),
            _networkService.get(
              ApiEndPoint.vendorHome,
              queryParameters: {'period': 'week'},
            ),
          ]);

          final home = _homeOf(checkedResponse(answers[0]));
          // The week only decorates the screen: a server that refuses the
          // period still has the day to show, so its refusal hides the
          // chart rather than failing the dashboard.
          final weekAnswer = ApiResponse.from(answers[1]);
          final week = weekAnswer.isOk ? _homeOf(weekAnswer) : null;

          final newest = VendorDashboardModel.needsOrders(home)
              ? OrderListModel.rowsFromApi(checkedResponse(
                  await _networkService.get(
                    ApiEndPoint.vendorOrders,
                    queryParameters: {'page': 1},
                  ),
                ))
              : const <VendorOrderSummaryModel>[];

          return VendorDashboardModel.fromApi(
            home,
            week: week,
            newestOrders: newest,
          );
        },
        fallbackMessage: 'dashboard_failed',
      );

  /// The payload, bare or nested under `home`.
  static Map<String, dynamic> _homeOf(ApiResponse envelope) {
    final data = envelope.dataMap;
    return data['home'] is Map ? asMap(data['home']) : data;
  }
}

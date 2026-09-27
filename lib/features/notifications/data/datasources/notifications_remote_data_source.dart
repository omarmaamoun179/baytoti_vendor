import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../models/notification_models.dart';
import 'notifications_data_source.dart';

/// The signed-in account's notifications on the live API — one endpoint
/// set for both apps: `GET /notifications` and
/// `PATCH /notifications/read-all`.
class NotificationsRemoteDataSource implements NotificationsDataSource {
  final NetworkService _networkService;

  NotificationsRemoteDataSource(this._networkService);

  @override
  Future<Either<Failure, NotificationFeedModel>> getNotifications(int page) =>
      guardedRequest(
        'NotificationsRemoteDataSource.getNotifications',
        () async {
          final response = await _networkService.get(
            ApiEndPoint.notifications,
            queryParameters: {'page': page},
          );
          return NotificationFeedModel.fromApi(checkedResponse(response));
        },
        fallbackMessage: 'notifications_failed',
      );

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardedRequest(
        'NotificationsRemoteDataSource.markAllRead',
        () async {
          checkedResponse(
            await _networkService.patch(ApiEndPoint.markNotificationsRead),
          );
          return unit;
        },
        fallbackMessage: 'notifications_mark_read_failed',
      );
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/notification_models.dart';

/// The vendor notifications endpoints. Only fixtures implement it today.
abstract class NotificationsDataSource {
  /// `GET /vendor/notifications?page=`.
  Future<Either<Failure, NotificationFeedModel>> getNotifications(int page);

  /// `POST /vendor/notifications/read` — see `ApiEndPoint`.
  Future<Either<Failure, Unit>> markAllRead();
}

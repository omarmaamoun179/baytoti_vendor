import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/notification_models.dart';

/// The family's notifications. [NotificationsRemoteDataSource] calls the
/// live API; [NotificationsMockDataSource] answers from fixtures.
abstract class NotificationsDataSource {
  /// One page, with how many are unread.
  Future<Either<Failure, NotificationFeedModel>> getNotifications(int page);

  /// Marks every notification read.
  Future<Either<Failure, Unit>> markAllRead();
}

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/vendor_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationFeed>> getNotifications(int page);

  /// Marks everything read — the bell's dot goes when the list is opened.
  Future<Either<Failure, Unit>> markAllRead();
}

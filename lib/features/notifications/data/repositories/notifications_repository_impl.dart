import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/vendor_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource _dataSource;

  NotificationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, NotificationFeed>> getNotifications(int page) =>
      _dataSource.getNotifications(page);

  @override
  Future<Either<Failure, Unit>> markAllRead() => _dataSource.markAllRead();
}

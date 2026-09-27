import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/vendor_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase
    implements UseCase<Either<Failure, NotificationFeed>, int> {
  final NotificationsRepository _repository;

  GetNotificationsUseCase(this._repository);

  @override
  Future<Either<Failure, NotificationFeed>> call(int page) =>
      _repository.getNotifications(page);
}

class MarkAllNotificationsReadUseCase
    implements UseCase<Either<Failure, Unit>, NoParams> {
  final NotificationsRepository _repository;

  MarkAllNotificationsReadUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.markAllRead();
}

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_state.dart';

class NotificationsCubit extends BaseCubit<NotificationsState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkAllNotificationsReadUseCase _markAllRead;

  /// Bumped by every read that replaces the list; see `OrdersCubit`.
  int _generation = 0;

  NotificationsCubit(this._getNotifications, this._markAllRead)
      : super(const NotificationsState());

  /// Reads the first page and, the first time it arrives, marks everything
  /// read — opening the list is reading it.
  Future<void> load({bool refresh = false}) async {
    final generation = ++_generation;
    final keep = refresh && state.hasContent;

    emit(state.copyWith(
      status: keep
          ? NotificationsStatus.refreshing
          : NotificationsStatus.loading,
    ));

    final result = await _getNotifications(1);
    if (generation != _generation) return;

    await result.fold<Future<void>>(
      (failure) async => emit(state.copyWith(
        status: keep ? NotificationsStatus.loaded : NotificationsStatus.error,
        errorMessage: failure.message,
      )),
      (feed) async {
        emit(state.copyWith(
          status: NotificationsStatus.loaded,
          page: feed.page,
        ));
        if (!state.markedRead && feed.unreadCount > 0) await _markRead();
      },
    );
  }

  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.loaded || !state.hasMore) return;

    final generation = _generation;
    emit(state.copyWith(status: NotificationsStatus.loadingMore));

    final result = await _getNotifications(state.page.nextPage);
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        errorMessage: failure.message,
      )),
      (feed) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        page: state.page.append(feed.page),
      )),
    );
  }

  /// Quiet either way: a failure only leaves the dot on the bell, which the
  /// next visit clears — so it is recorded, not toasted.
  Future<void> _markRead() async {
    final result = await _markAllRead(NoParams());
    result.fold(
      (_) => emit(state.copyWith(markedRead: false)),
      (_) => emit(state.copyWith(markedRead: true)),
    );
  }
}

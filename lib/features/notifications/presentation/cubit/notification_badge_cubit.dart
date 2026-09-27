import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/abstract/count_badge_state.dart';
import '../../../../core/app/session_notifier.dart';
import '../../domain/usecases/notifications_usecases.dart';

/// Unread notifications, for the dot on the bell.
///
/// App-wide: the bell sits in more than one header, and two instances
/// would disagree. Read when a session begins, cleared when it ends
/// ([SessionNotifier]), and cleared by the notifications screen once it has
/// marked everything read.
class NotificationBadgeCubit extends BaseCubit<CountBadgeState> {
  final GetNotificationsUseCase _getNotifications;
  final SessionNotifier _sessionNotifier;

  NotificationBadgeCubit(this._getNotifications, this._sessionNotifier)
      : super(const CountBadgeState()) {
    _sessionNotifier.addListener(_onSessionChanged);
    if (_sessionNotifier.isAuthenticated) refresh();
  }

  void _onSessionChanged() {
    if (_sessionNotifier.isAuthenticated) {
      refresh();
    } else {
      emit(const CountBadgeState());
    }
  }

  /// The first page's `unread_count`. A failure keeps the last count.
  Future<void> refresh() async {
    final result = await _getNotifications(1);
    if (!_sessionNotifier.isAuthenticated) return;

    result.fold(
      (_) => emit(state.failed()),
      (feed) => emit(state.loaded(feed.unreadCount)),
    );
  }

  void clear() => emit(state.loaded(0));

  @override
  Future<void> close() {
    _sessionNotifier.removeListener(_onSessionChanged);
    return super.close();
  }
}

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/abstract/count_badge_state.dart';
import '../../../../core/app/session_notifier.dart';

/// New orders waiting for the family, for the badge on the orders tab.
///
/// It reads nothing itself. The dashboard (`kpis.new_orders`) and the orders
/// list (`counts.new`) both carry the server's count, and whichever read
/// last hands it over with [reportCount] — so the badge never costs a
/// request of its own. App-wide, and forgotten when the session ends
/// ([SessionNotifier]).
class OrdersBadgeCubit extends BaseCubit<CountBadgeState> {
  final SessionNotifier _sessionNotifier;

  OrdersBadgeCubit(this._sessionNotifier) : super(const CountBadgeState()) {
    _sessionNotifier.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    if (!_sessionNotifier.isAuthenticated) emit(const CountBadgeState());
  }

  void reportCount(int count) => emit(state.loaded(count));

  @override
  Future<void> close() {
    _sessionNotifier.removeListener(_onSessionChanged);
    return super.close();
  }
}

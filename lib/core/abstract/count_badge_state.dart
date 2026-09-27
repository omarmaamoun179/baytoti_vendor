import 'package:equatable/equatable.dart';

enum CountBadgeStatus { initial, loaded, failed }

/// The state behind a count badge — new orders on the tab bar, unread
/// notifications on the bell.
///
/// A failed re-read keeps the last count. A badge that dropped to zero on a
/// flaky network would claim there is nothing waiting.
class CountBadgeState extends Equatable {
  final int count;
  final CountBadgeStatus status;

  const CountBadgeState({
    this.count = 0,
    this.status = CountBadgeStatus.initial,
  });

  CountBadgeState loaded(int count) =>
      CountBadgeState(count: count, status: CountBadgeStatus.loaded);

  CountBadgeState failed() =>
      CountBadgeState(count: count, status: CountBadgeStatus.failed);

  @override
  List<Object?> get props => [count, status];
}

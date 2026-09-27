import 'package:equatable/equatable.dart';

/// One page of a list endpoint, plus where it sits in the whole.
///
/// The page counters come from the response's `meta`, and they — not the
/// number of rows that arrived — decide whether another page exists. A
/// filtered page can be shorter than `perPage` without being the last one, and
/// a page requested past the end comes back empty while `meta` still reports
/// the real `lastPage`. Counting rows cannot tell those two apart; `meta` can.
class Paged<T> extends Equatable {
  final List<T> items;

  /// The page these [items] came from, as the server reported it. A request
  /// past the end echoes the page that was asked for, so this can exceed
  /// [lastPage].
  final int currentPage;

  final int lastPage;

  /// Rows per page the server actually applied, which is not necessarily the
  /// number asked for.
  final int perPage;

  /// Rows across every page, for a "36 pieces" line.
  final int total;

  const Paged({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 0,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;

  bool get isEmpty => items.isEmpty;

  /// The page to ask for next. Meaningless unless [hasMore].
  int get nextPage => currentPage + 1;

  /// Adds a freshly loaded page to the end of this one, taking its position as
  /// the new position. Used by a cubit appending to a list already on screen.
  Paged<T> append(Paged<T> next) => Paged<T>(
        items: [...items, ...next.items],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        perPage: next.perPage,
        total: next.total,
      );

  @override
  List<Object?> get props => [items, currentPage, lastPage, perPage, total];
}

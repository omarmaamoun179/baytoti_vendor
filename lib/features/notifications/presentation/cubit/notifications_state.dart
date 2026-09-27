import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_notification.dart';

enum NotificationsStatus { initial, loading, loaded, refreshing, loadingMore, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final Paged<VendorNotification> page;
  final String? errorMessage;

  /// Everything has been marked read on the server, so the bell's dot can
  /// go. The rows keep the highlight they opened with, for this visit.
  final bool markedRead;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.page = const Paged<VendorNotification>(),
    this.errorMessage,
    this.markedRead = false,
  });

  List<VendorNotification> get items => page.items;

  bool get hasMore => page.hasMore;

  bool get isLoadingMore => status == NotificationsStatus.loadingMore;

  bool get hasContent =>
      status == NotificationsStatus.loaded ||
      status == NotificationsStatus.refreshing ||
      status == NotificationsStatus.loadingMore;

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again.
  NotificationsState copyWith({
    NotificationsStatus? status,
    Paged<VendorNotification>? page,
    String? errorMessage,
    bool? markedRead,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      page: page ?? this.page,
      errorMessage: errorMessage,
      markedRead: markedRead ?? this.markedRead,
    );
  }

  @override
  List<Object?> get props => [status, page, errorMessage, markedRead];
}

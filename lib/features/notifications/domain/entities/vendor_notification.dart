import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';

/// The contract's vendor notification `type`.
enum NotificationType {
  newOrder('new_order'),
  orderStatus('order_status'),
  productApproved('product_approved'),
  rating('rating'),
  lowStock('low_stock'),
  exhibitionInvite('exhibition_invite'),

  /// A type this build does not know — drawn with a neutral tag.
  other('');

  const NotificationType(this.wire);

  final String wire;

  static NotificationType fromWire(String? value) => values.firstWhere(
        (type) => type.wire == value && type != other,
        orElse: () => other,
      );
}

/// What a notification opens.
enum NotificationTargetKind { order, product, none }

class NotificationTarget extends Equatable {
  final NotificationTargetKind kind;
  final String? id;

  const NotificationTarget({this.kind = NotificationTargetKind.none, this.id});

  bool get opensSomething =>
      kind != NotificationTargetKind.none && (id?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [kind, id];
}

class VendorNotification extends Equatable {
  final String id;
  final NotificationType type;
  final bool isRead;

  /// Already in the app's language.
  final String title;
  final String body;

  final DateTime? createdAt;
  final NotificationTarget target;

  const VendorNotification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.title,
    required this.body,
    this.createdAt,
    this.target = const NotificationTarget(),
  });

  VendorNotification read() => VendorNotification(
        id: id,
        type: type,
        isRead: true,
        title: title,
        body: body,
        createdAt: createdAt,
        target: target,
      );

  @override
  List<Object?> get props =>
      [id, type, isRead, title, body, createdAt, target];
}

/// One page of notifications, and how many are unread across all of them.
class NotificationFeed extends Equatable {
  final Paged<VendorNotification> page;
  final int unreadCount;

  const NotificationFeed({required this.page, required this.unreadCount});

  @override
  List<Object?> get props => [page, unreadCount];
}

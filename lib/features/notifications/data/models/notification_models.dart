import '../../../../core/domain/paged.dart';
import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_notification.dart';

/// A row of `GET /vendor/notifications`, in the shape the contract gives the
/// customer's:
///
/// ```json
/// {"id": "ntf_9", "type": "new_order", "is_read": false,
///  "title": "طلب جديد BT-2041", "body": "نورة العنزي · 9.250 د.ك",
///  "created_at": "2026-09-21T14:10:00Z",
///  "target": {"kind": "order", "id": "ord_2041"}}
/// ```
class VendorNotificationModel extends VendorNotification {
  const VendorNotificationModel({
    required super.id,
    required super.type,
    required super.isRead,
    required super.title,
    required super.body,
    super.createdAt,
    super.target,
  });

  factory VendorNotificationModel.fromJson(Map<String, dynamic> json) {
    final target = asMap(json['target']);

    return VendorNotificationModel(
      id: requireString(json['id'], 'id'),
      type: NotificationType.fromWire(asString(json['type'])),
      isRead: asBool(json['is_read']) ?? true,
      title: asString(json['title']) ?? '',
      body: asString(json['body']) ?? '',
      createdAt: asDate(json['created_at']),
      target: NotificationTarget(
        kind: switch (asString(target['kind'])) {
          'order' => NotificationTargetKind.order,
          'product' => NotificationTargetKind.product,
          _ => NotificationTargetKind.none,
        },
        id: asString(target['id']),
      ),
    );
  }
}

/// `{"unread_count": 3, "items": [...], "meta": {...}}`.
class NotificationFeedModel extends NotificationFeed {
  const NotificationFeedModel({required super.page, required super.unreadCount});

  factory NotificationFeedModel.fromJson(Map<String, dynamic> json) {
    final meta = asMap(json['meta']);
    final items = [
      for (final row in asMapList(json['items']))
        VendorNotificationModel.fromJson(row),
    ];

    return NotificationFeedModel(
      page: Paged<VendorNotification>(
        items: items,
        currentPage: asInt(meta['current_page']) ?? 1,
        lastPage: asInt(meta['last_page']) ?? 1,
        perPage: asInt(meta['per_page']) ?? items.length,
        total: asInt(meta['total']) ?? items.length,
      ),
      unreadCount: asInt(json['unread_count']) ??
          items.where((item) => !item.isRead).length,
    );
  }
}

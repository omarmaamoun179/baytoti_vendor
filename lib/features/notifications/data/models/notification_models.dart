import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_notification.dart';

/// A notification. The fixtures answer in the shape the design contract
/// gives the customer's, read by [VendorNotificationModel.fromJson]:
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

  /// A row of the live `GET /notifications`, the OpenAPI
  /// `NotificationResource`:
  ///
  /// ```json
  /// {"id": "9b1c…", "type": "new_order", "title": "…", "body": "…",
  ///  "data": {"entity": "order", "entity_id": "1258", "action": "created"},
  ///  "read_at": null, "created_at": "2026-09-21T14:10:00.000000Z"}
  /// ```
  ///
  /// Unread is a null `read_at`. `type` may be a short key or a Laravel
  /// notification class, so the kind is read from it and from `data`
  /// ([_typeOf]); what it opens is `data.entity` and `data.entity_id`.
  factory VendorNotificationModel.fromApi(Map<String, dynamic> json) {
    final data = asMap(json['data']);
    final entity = asString(data['entity'])?.toLowerCase();

    return VendorNotificationModel(
      id: requireString(json['id'], 'id'),
      type: _typeOf(asString(json['type']), entity, asString(data['action'])),
      isRead: asString(json['read_at']) != null,
      title: asString(json['title']) ?? '',
      body: asString(json['body']) ?? '',
      createdAt: asDate(json['created_at']),
      target: NotificationTarget(
        kind: switch (entity) {
          'order' => NotificationTargetKind.order,
          'product' => NotificationTargetKind.product,
          _ => NotificationTargetKind.none,
        },
        id: asString(data['entity_id']),
      ),
    );
  }

  /// A known key as it is; otherwise the words in the class name and the
  /// entity's action — `App\Notifications\NewOrderNotification`, or
  /// `{entity: order, action: created}`, is a new order.
  static NotificationType _typeOf(
    String? type,
    String? entity,
    String? action,
  ) {
    final known = NotificationType.fromWire(type);
    if (known != NotificationType.other) return known;

    final words = '${type ?? ''} ${entity ?? ''} ${action ?? ''}'.toLowerCase();
    bool has(String word) => words.contains(word);

    if (has('order')) {
      return has('new') || has('created') || has('placed')
          ? NotificationType.newOrder
          : NotificationType.orderStatus;
    }
    if (has('product') && has('approv')) {
      return NotificationType.productApproved;
    }
    if (has('review') || has('rating')) return NotificationType.rating;
    if (has('stock') || has('availab')) return NotificationType.lowStock;
    return NotificationType.other;
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

  /// One live page, positioned by `meta`. The page carries no unread
  /// count; its own unread rows stand in — the newest come first, so the
  /// first page is where they are, and the bell only shows whether any are.
  factory NotificationFeedModel.fromApi(ApiResponse envelope) {
    final items = [
      for (final row in asMapList(envelope.dataList))
        if (asString(row['id']) != null) VendorNotificationModel.fromApi(row),
    ];

    return NotificationFeedModel(
      page: Paged<VendorNotification>(
        items: items,
        currentPage: envelope.currentPage,
        lastPage: envelope.lastPage,
        perPage: envelope.perPage,
        total: envelope.total,
      ),
      unreadCount: items.where((item) => !item.isRead).length,
    );
  }
}

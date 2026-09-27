import 'package:baytoti_vendor/features/notifications/data/models/notification_models.dart';
import 'package:baytoti_vendor/features/notifications/domain/entities/vendor_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the live notifications', () {
    test('a row reads its kind, target and whether it was read', () {
      final row = VendorNotificationModel.fromApi({
        'id': '9b1c',
        'type': 'new_order',
        'title': 'طلب جديد',
        'body': 'نورة العنزي',
        'data': {'entity': 'order', 'entity_id': '1258', 'action': 'created'},
        'read_at': null,
        'created_at': '2026-09-21T14:10:00.000000Z',
      });

      expect(row.type, NotificationType.newOrder);
      expect(row.isRead, isFalse);
      expect(row.target.kind, NotificationTargetKind.order);
      expect(row.target.id, '1258');
    });

    test('a Laravel class name is read for its kind', () {
      NotificationType kindOf(String type, [Map<String, String>? data]) =>
          VendorNotificationModel.fromApi({
            'id': '1',
            'type': type,
            'data': ?data,
          }).type;

      expect(
        kindOf(r'App\Notifications\NewOrderNotification'),
        NotificationType.newOrder,
      );
      expect(
        kindOf(r'App\Notifications\OrderStatusUpdated'),
        NotificationType.orderStatus,
      );
      expect(
        kindOf(r'App\Notifications\ProductApproved'),
        NotificationType.productApproved,
      );
      expect(kindOf('something_else'), NotificationType.other);
    });

    test('read rows are read', () {
      final row = VendorNotificationModel.fromApi({
        'id': '2',
        'type': 'order_status',
        'read_at': '2026-09-21T15:00:00.000000Z',
      });

      expect(row.isRead, isTrue);
    });
  });
}

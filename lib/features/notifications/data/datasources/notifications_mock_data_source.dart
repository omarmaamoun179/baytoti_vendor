import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../models/notification_models.dart';
import 'notifications_data_source.dart';

/// A fixture notification.
class _NotificationRecord {
  final String id;
  final String type;
  final Localized title;
  final Localized body;
  final Duration ago;
  final String? targetKind;
  final String? targetId;
  bool isRead;

  _NotificationRecord(
    this.id,
    this.type,
    this.title,
    this.body,
    this.ago, {
    this.targetKind,
    this.targetId,
    this.isRead = true,
  });
}

/// The design's notifications — two new orders, an approval, a rating, an
/// item out of stock, an exhibition invite — and two older ones. Their
/// links point at the order and product fixtures.
class NotificationsMockDataSource implements NotificationsDataSource {
  static const int _perPage = 20;

  final MockLocale _locale;
  final DateTime _now = DateTime.now();

  late final List<_NotificationRecord> _records = [
    _NotificationRecord(
      'ntf_8',
      'new_order',
      const Localized('طلب جديد BT-2041', 'New order BT-2041'),
      const Localized('نورة العنزي · 9.250 د.ك', 'Noura Al-Anzi · 9.250 KWD'),
      const Duration(minutes: 4),
      targetKind: 'order',
      targetId: 'ord_2041',
      isRead: false,
    ),
    _NotificationRecord(
      'ntf_7',
      'new_order',
      const Localized('طلب جديد BT-2040', 'New order BT-2040'),
      const Localized('فهد المطيري · استلام', 'Fahad Al-Mutairi · pickup'),
      const Duration(minutes: 18),
      targetKind: 'order',
      targetId: 'ord_2040',
      isRead: false,
    ),
    _NotificationRecord(
      'ntf_6',
      'product_approved',
      const Localized('تم اعتماد «معمول بالتمر»', '“Date maamoul” approved'),
      const Localized(
        'المنتج ظاهر الآن للعملاء.',
        'The product is now live for customers.',
      ),
      const Duration(hours: 3),
      targetKind: 'product',
      targetId: 'prd_4',
    ),
    _NotificationRecord(
      'ntf_5',
      'rating',
      const Localized('تقييم جديد ★ ٥', 'New rating ★ 5'),
      const Localized('على كيك التمر بالهيل.', 'On the cardamom date cake.'),
      const Duration(hours: 22),
      targetKind: 'product',
      targetId: 'prd_1',
    ),
    _NotificationRecord(
      'ntf_4',
      'low_stock',
      const Localized(
        'مخزون «كنافة بالقشطة» صفر',
        '“Cream kunafa” is out of stock',
      ),
      const Localized(
        'أُخفي المنتج تلقائياً.',
        'The product was hidden automatically.',
      ),
      const Duration(hours: 26),
      targetKind: 'product',
      targetId: 'prd_3',
    ),
    _NotificationRecord(
      'ntf_3',
      'exhibition_invite',
      const Localized(
        'دعوة للمشاركة في معرض الخريف',
        'Invitation to the Autumn Market',
      ),
      const Localized('الرد قبل ٢٨ سبتمبر.', 'Respond before 28 September.'),
      const Duration(days: 3),
    ),
    _NotificationRecord(
      'ntf_2',
      'order_status',
      const Localized('تم تسليم الطلب BT-2029', 'Order BT-2029 delivered'),
      const Localized(
        'سارة العجمي استلمت طلبها.',
        'Sara Al-Ajmi has her order.',
      ),
      const Duration(days: 4),
      targetKind: 'order',
      targetId: 'ord_2029',
    ),
    _NotificationRecord(
      'ntf_1',
      'rating',
      const Localized('تقييم جديد ★ ٤', 'New rating ★ 4'),
      const Localized('على درابيل محشية.', 'On the filled darabeel.'),
      const Duration(days: 6),
      targetKind: 'product',
      targetId: 'prd_2',
    ),
  ];

  NotificationsMockDataSource(this._locale);

  @override
  Future<Either<Failure, NotificationFeedModel>> getNotifications(int page) =>
      guardedRequest(
        'NotificationsMockDataSource.getNotifications',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();
          final rows = _records.skip((page - 1) * _perPage).take(_perPage);

          return NotificationFeedModel.fromJson({
            'unread_count': _records.where((r) => !r.isRead).length,
            'items': [
              for (final record in rows)
                {
                  'id': record.id,
                  'type': record.type,
                  'is_read': record.isRead,
                  'title': record.title.pick(ar),
                  'body': record.body.pick(ar),
                  'created_at':
                      _now.subtract(record.ago).toUtc().toIso8601String(),
                  'target': {'kind': record.targetKind, 'id': record.targetId},
                },
            ],
            'meta': {
              'current_page': page,
              'last_page': (_records.length / _perPage).ceil().clamp(1, 1000),
              'per_page': _perPage,
              'total': _records.length,
            },
          });
        },
        fallbackMessage: 'notifications_failed',
      );

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardedRequest(
        'NotificationsMockDataSource.markAllRead',
        () async {
          await Future<void>.delayed(mockLatency);
          for (final record in _records) {
            record.isRead = true;
          }
          return unit;
        },
        fallbackMessage: 'notifications_failed',
      );
}

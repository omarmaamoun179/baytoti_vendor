import '../../../../core/mock/mock_locale.dart';
import '../../domain/entities/order_status.dart';

/// One line of a fixture order.
class OrderLineRecord {
  final String productId;
  final Localized name;
  final int quantity;
  final int lineTotalFils;

  const OrderLineRecord(
    this.productId,
    this.name,
    this.quantity,
    this.lineTotalFils,
  );
}

/// A fixture order as the fake backend holds it. [status] changes as the
/// family moves it along.
class OrderRecord {
  final String id;
  final String reference;
  final Localized customer;
  final String phoneLast4;
  final FulfilmentMethod fulfilment;

  /// Null for a pickup.
  final Localized? address;

  final DateTime placedAt;
  final List<OrderLineRecord> lines;
  OrderStatus status;
  String? rejectReason;

  OrderRecord({
    required this.id,
    required this.reference,
    required this.customer,
    required this.phoneLast4,
    required this.fulfilment,
    this.address,
    required this.placedAt,
    required this.lines,
    required this.status,
  });

  int get totalFils =>
      lines.fold(0, (sum, line) => sum + line.lineTotalFils);

  int get itemCount => lines.length;

  /// The one move the family can make — the design's path, placed through
  /// delivered, with no "out for delivery" stop of its own.
  OrderStatus? get nextStatus => switch (status) {
        OrderStatus.placed => OrderStatus.accepted,
        OrderStatus.accepted => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready || OrderStatus.outForDelivery =>
          OrderStatus.delivered,
        _ => null,
      };

  /// Only an order not yet accepted can be turned down.
  bool get canReject => status == OrderStatus.placed;
}

/// The fixture orders — the design's five, and seven more so every tab has
/// something and the "all" tab runs to a second page. Built relative to
/// the moment the app starts, and held for the run so a status change
/// survives leaving the screen.
///
/// Shared by the orders and dashboard fixtures, which is what keeps the new
/// orders on the dashboard, the badge and the "new" tab in agreement.
class OrderFixtures {
  late final List<OrderRecord> orders = _build(DateTime.now());

  static const Localized _cardamomCake =
      Localized('كيك التمر بالهيل', 'Cardamom date cake');
  static const Localized _darabeel =
      Localized('درابيل محشية', 'Filled darabeel');
  static const Localized _saffron =
      Localized('زعفران معبأ يدوياً', 'Hand-packed saffron');
  static const Localized _sadu =
      Localized('وسادة سدو مطرزة', 'Embroidered Sadu cushion');
  static const Localized _bread =
      Localized('خبز التنور الطازج', 'Fresh tanoor bread');
  static const Localized _kabsa =
      Localized('بهار الكبسة المنزلي', 'House kabsa spice');
  static const Localized _maamoul = Localized('معمول بالتمر', 'Date maamoul');
  static const Localized _kunafa = Localized('كنافة بالقشطة', 'Cream kunafa');
  static const Localized _box = Localized('صندوق ضيافة', 'Hospitality box');

  static List<OrderRecord> _build(DateTime now) {
    OrderRecord order(
      int number,
      Localized customer,
      String last4,
      OrderStatus status,
      Duration ago,
      List<OrderLineRecord> lines, {
      Localized? address,
    }) =>
        OrderRecord(
          id: 'ord_$number',
          reference: 'BT-$number',
          customer: customer,
          phoneLast4: last4,
          fulfilment: address == null
              ? FulfilmentMethod.pickup
              : FulfilmentMethod.delivery,
          address: address,
          placedAt: now.subtract(ago),
          lines: lines,
          status: status,
        );

    return [
      order(
        2041,
        const Localized('نورة العنزي', 'Noura Al-Anzi'),
        '2244',
        OrderStatus.placed,
        const Duration(minutes: 4),
        const [
          OrderLineRecord('prd_1', _cardamomCake, 1, 4250),
          OrderLineRecord('prd_2', _darabeel, 2, 5000),
        ],
        address: const Localized(
          'حولي · قطعة ٣، شارع ١٢',
          'Hawalli · Block 3, Street 12',
        ),
      ),
      order(
        2040,
        const Localized('فهد المطيري', 'Fahad Al-Mutairi'),
        '7710',
        OrderStatus.placed,
        const Duration(minutes: 18),
        const [OrderLineRecord('prd_6', _saffron, 1, 6750)],
      ),
      order(
        2039,
        const Localized('مريم الكندري', 'Maryam Al-Kandari'),
        '3391',
        OrderStatus.accepted,
        const Duration(minutes: 55),
        const [OrderLineRecord('prd_4', _maamoul, 2, 7800)],
        address: const Localized(
          'الفروانية · قطعة ٤',
          'Farwaniya · Block 4',
        ),
      ),
      order(
        2038,
        const Localized('دلال السبيعي', 'Dalal Al-Subaie'),
        '5068',
        OrderStatus.preparing,
        const Duration(hours: 2),
        const [
          OrderLineRecord('prd_7', _sadu, 1, 9500),
          OrderLineRecord('prd_8', _bread, 2, 3000),
        ],
        address: const Localized('السالمية · قطعة ٧', 'Salmiya · Block 7'),
      ),
      order(
        2035,
        const Localized('يوسف الرشيد', 'Yousef Al-Rashid'),
        '9123',
        OrderStatus.ready,
        const Duration(hours: 5),
        const [OrderLineRecord('prd_1', _cardamomCake, 1, 4250)],
      ),
      order(
        2033,
        const Localized('خالد العازمي', 'Khaled Al-Azmi'),
        '4402',
        OrderStatus.delivered,
        const Duration(hours: 20),
        const [OrderLineRecord('prd_3', _kunafa, 1, 5500)],
      ),
      order(
        2031,
        const Localized('أمل الخالدي', 'Amal Al-Khalidi'),
        '6617',
        OrderStatus.delivered,
        const Duration(hours: 26),
        const [
          OrderLineRecord('prd_9', _kabsa, 3, 5700),
          OrderLineRecord('prd_8', _bread, 2, 2700),
        ],
        address: const Localized('الجهراء · قطعة ١', 'Jahra · Block 1'),
      ),
      order(
        2029,
        const Localized('سارة العجمي', 'Sara Al-Ajmi'),
        '1180',
        OrderStatus.delivered,
        const Duration(days: 2, hours: 3),
        const [OrderLineRecord('prd_5', _box, 1, 12000)],
        address: const Localized('الأحمدي · قطعة ٢', 'Ahmadi · Block 2'),
      ),
      order(
        2027,
        const Localized('عبدالله الهاجري', 'Abdullah Al-Hajri'),
        '2957',
        OrderStatus.rejected,
        const Duration(days: 3),
        const [OrderLineRecord('prd_3', _kunafa, 2, 11000)],
        address: const Localized('السالمية · قطعة ١٠', 'Salmiya · Block 10'),
      ),
      order(
        2025,
        const Localized('حصة العتيبي', 'Hessa Al-Otaibi'),
        '8834',
        OrderStatus.delivered,
        const Duration(days: 4, hours: 6),
        const [OrderLineRecord('prd_2', _darabeel, 4, 11000)],
      ),
      order(
        2022,
        const Localized('بدر الشمري', 'Bader Al-Shammari'),
        '7345',
        OrderStatus.delivered,
        const Duration(days: 5),
        const [
          OrderLineRecord('prd_4', _maamoul, 1, 3900),
          OrderLineRecord('prd_1', _cardamomCake, 1, 4250),
        ],
        address: const Localized('حولي · قطعة ٩', 'Hawalli · Block 9'),
      ),
      order(
        2019,
        const Localized('لولوة الدوسري', 'Lulwa Al-Dosari'),
        '6021',
        OrderStatus.delivered,
        const Duration(days: 6, hours: 2),
        const [OrderLineRecord('prd_6', _saffron, 2, 13500)],
        address: const Localized('الجهراء · قطعة ٥', 'Jahra · Block 5'),
      ),
    ];
  }
}

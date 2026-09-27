import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';

import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json_read.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';

/// A row of `GET /vendor/orders`:
///
/// ```json
/// {"id": "ord_2041", "reference": "BT-2041", "status": "placed",
///  "customer_name": "نورة العنزي", "item_count": 2, "total_fils": 9250,
///  "fulfilment_method": "delivery", "placed_at": "2026-09-21T14:10:00Z"}
/// ```
///
/// The contract's example shows `total_display` and `placed_display`; its
/// conventions promise `*_fils` and an ISO time beside every display string,
/// and those are what is read, so the app formats money and time itself.
class VendorOrderSummaryModel extends VendorOrderSummary {
  const VendorOrderSummaryModel({
    required super.id,
    required super.reference,
    required super.status,
    required super.customerName,
    required super.itemCount,
    required super.totalFils,
    required super.fulfilment,
    super.placedAt,
  });

  factory VendorOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');

    return VendorOrderSummaryModel(
      id: id,
      reference: asString(json['reference']) ?? id,
      status: OrderStatus.fromWire(asString(json['status'])),
      customerName: asString(json['customer_name']) ?? '',
      itemCount: asInt(json['item_count']) ?? 0,
      totalFils: asInt(json['total_fils']) ?? 0,
      fulfilment: FulfilmentMethod.fromWire(
        asString(json['fulfilment_method']),
      ),
      placedAt: asDate(json['placed_at']),
    );
  }

  /// A row of the live `GET /vendor/orders` — see [orderStatusFromApi] for
  /// the status, and [VendorOrderModel.fromApi] for the resource.
  factory VendorOrderSummaryModel.fromApi(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');
    final address = asMap(json['address']);

    return VendorOrderSummaryModel(
      id: id,
      reference: asString(json['order_number']) ?? id,
      status: orderStatusFromApi(asString(json['status'])),
      customerName: _customerNameOf(json),
      itemCount: asInt(json['items_count']) ?? asMapList(json['items']).length,
      totalFils: _filsOf(asMap(json['financials'])['total']),
      // An order with an address is delivered; the resource has no pickup.
      fulfilment: address.isEmpty
          ? FulfilmentMethod.pickup
          : FulfilmentMethod.delivery,
      placedAt: asDate(json['created_at']),
    );
  }
}

/// `GET /vendor/orders?state=&page=`:
///
/// ```json
/// {"counts": {"all": 5, "new": 2, "preparing": 2, "done": 1},
///  "items": [ … ],
///  "meta": {"current_page": 1, "last_page": 1, "per_page": 10, "total": 5}}
/// ```
///
/// The contract pages with `next_cursor`; the app pages the way the core
/// does ([Paged], positioned by `meta`), and a cursor API needs this read
/// and the query changed together.
class OrderListModel extends OrderList {
  const OrderListModel({required super.page, required super.counts});

  factory OrderListModel.fromJson(Map<String, dynamic> json) {
    final counts = asMap(json['counts']);
    final meta = asMap(json['meta']);
    final items = [
      for (final row in asMapList(json['items']))
        VendorOrderSummaryModel.fromJson(row),
    ];

    return OrderListModel(
      page: Paged<VendorOrderSummary>(
        items: items,
        currentPage: asInt(meta['current_page']) ?? 1,
        lastPage: asInt(meta['last_page']) ?? 1,
        perPage: asInt(meta['per_page']) ?? items.length,
        total: asInt(meta['total']) ?? items.length,
      ),
      counts: OrderCounts(
        all: asInt(counts['all']) ?? 0,
        fresh: asInt(counts['new']) ?? 0,
        preparing: asInt(counts['preparing']) ?? 0,
        done: asInt(counts['done']) ?? 0,
      ),
    );
  }

  /// The rows of one live page, positioned by `meta`.
  static List<VendorOrderSummaryModel> rowsFromApi(ApiResponse envelope) => [
        for (final row in asMapList(envelope.dataList))
          if (asString(row['id']) != null) VendorOrderSummaryModel.fromApi(row),
      ];

  /// The tab counts the live API does not send, worked out from [newest] —
  /// the first page, which holds the orders still moving, since those are
  /// the newest. "All" is `meta.total`; "done" is what the other two leave
  /// of it, so an order on a later page is counted there.
  static OrderCounts countsFromApi(
    List<VendorOrderSummary> newest, {
    required int total,
  }) {
    final fresh = newest.where((o) => OrderTab.fresh.holds(o.status)).length;
    final preparing =
        newest.where((o) => OrderTab.preparing.holds(o.status)).length;

    return OrderCounts(
      all: total,
      fresh: fresh,
      preparing: preparing,
      done: math.max(0, total - fresh - preparing),
    );
  }
}

/// `GET /vendor/orders/{id}`, and the answer to a status move or a
/// rejection:
///
/// ```json
/// {"id": "ord_2041", "reference": "BT-2041", "status": "placed",
///  "placed_at": "…", "fulfilment_method": "delivery",
///  "customer": {"name": "…", "phone_masked": "•••• 2244",
///               "call_token": "ct_a91", "address": "حولي · قطعة ٣"},
///  "items": [{"product_id": "prd_1", "name": "…", "quantity": 1,
///             "line_total_fils": 4250}],
///  "payout": {"gross_fils": 9250, "commission_fils": null,
///             "note": "المبلغ قبل خصم عمولة المنصة"},
///  "next_status": "accepted", "can_reject": true}
/// ```
class VendorOrderModel extends VendorOrder {
  const VendorOrderModel({
    required super.id,
    required super.reference,
    required super.status,
    super.placedAt,
    required super.fulfilment,
    required super.customer,
    super.lines,
    required super.payout,
    super.nextStatus,
    super.canReject,
  });

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');
    final customer = asMap(json['customer']);
    final payout = asMap(json['payout']);
    final next = asString(json['next_status']);
    final lines = [
      for (final line in asMapList(json['items']))
        OrderLine(
          productId: asString(line['product_id']) ?? '',
          name: asString(line['name']) ?? '',
          quantity: asInt(line['quantity']) ?? 1,
          lineTotalFils: asInt(line['line_total_fils']) ?? 0,
          imageUrl: asString(asMap(line['image'])['url']),
        ),
    ];

    return VendorOrderModel(
      id: id,
      reference: asString(json['reference']) ?? id,
      status: OrderStatus.fromWire(asString(json['status'])),
      placedAt: asDate(json['placed_at']),
      fulfilment: FulfilmentMethod.fromWire(
        asString(json['fulfilment_method']),
      ),
      customer: OrderCustomer(
        name: asString(customer['name']) ?? '',
        phoneMasked: asString(customer['phone_masked']),
        address: asString(customer['address']),
      ),
      lines: lines,
      payout: OrderPayout(
        grossFils: asInt(payout['gross_fils']) ??
            lines.fold<int>(0, (sum, line) => sum + line.lineTotalFils),
        commissionFils: asInt(payout['commission_fils']),
        note: asString(payout['note']),
      ),
      // A status this build does not know is no move to offer.
      nextStatus: switch (OrderStatus.fromWire(next)) {
        OrderStatus.unknown => null,
        final status => status,
      },
      canReject: asBool(json['can_reject']) ?? false,
    );
  }

  /// The live `OrderResource`:
  ///
  /// ```json
  /// {"id": 12, "order_number": "ORD-2026-1258", "status": "pending",
  ///  "financials": {"subtotal": "8.500", "discount": "0.000",
  ///                 "shipping_fee": "0.750", "total": "9.250"},
  ///  "notes": null, "store": {"id": 8, "name": "…", "slug": "…"},
  ///  "address": {"recipient_name": "نورة العنزي", "phone": "96551502244",
  ///              "city": "…", "area": "حولي", "block": "3",
  ///              "street": "…", "building": "12", …},
  ///  "items_count": 2,
  ///  "items": [{"id": 1, "product_id": 3, "product_name": "…",
  ///             "unit_price": "4.250", "quantity": 1, "total": "4.250"}],
  ///  "created_at": "2026-09-21T14:10:00.000000Z"}
  /// ```
  ///
  /// Money arrives as dinars in strings; the customer is the address's
  /// recipient, whose number is masked here — it is not the family's to
  /// see. The API carries no next move: the one after [status] on the
  /// API's path is offered, and only a new order can be turned down
  /// (`cancelled`). There is no payout breakdown, so the gross is the
  /// order's total and the commission stays unknown.
  factory VendorOrderModel.fromApi(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');
    final address = asMap(json['address']);
    final status = orderStatusFromApi(asString(json['status']));
    final lines = [
      for (final line in asMapList(json['items']))
        OrderLine(
          productId: asString(line['product_id']) ?? '',
          name: asString(line['product_name']) ?? asString(line['name']) ?? '',
          quantity: asInt(line['quantity']) ?? 1,
          lineTotalFils: line['total'] == null
              ? _filsOf(line['unit_price']) * (asInt(line['quantity']) ?? 1)
              : _filsOf(line['total']),
        ),
    ];
    final total = asMap(json['financials'])['total'];

    return VendorOrderModel(
      id: id,
      reference: asString(json['order_number']) ?? id,
      status: status,
      placedAt: asDate(json['created_at']),
      fulfilment: address.isEmpty
          ? FulfilmentMethod.pickup
          : FulfilmentMethod.delivery,
      customer: OrderCustomer(
        name: _customerNameOf(json),
        phoneMasked: _masked(asString(address['phone'])),
        address: _addressLine(address),
      ),
      lines: lines,
      payout: OrderPayout(
        grossFils: total == null
            ? lines.fold<int>(0, (sum, line) => sum + line.lineTotalFils)
            : _filsOf(total),
      ),
      nextStatus: _nextOnApi(status),
      canReject: status == OrderStatus.placed,
    );
  }

  /// A single order, bare or under `order`.
  static VendorOrderModel fromResponse(ApiResponse envelope) =>
      VendorOrderModel.fromApi(orderMapOf(envelope));

  static Map<String, dynamic> orderMapOf(ApiResponse envelope) {
    final data = envelope.dataMap;
    return data['order'] is Map ? asMap(data['order']) : data;
  }
}

// ── The live API's words ─────────────────────────────────────────────

/// The live API's status onto the app's. `shipped` is on its way — for a
/// home kitchen, out for delivery.
OrderStatus orderStatusFromApi(String? value) =>
    switch (value?.trim().toLowerCase()) {
      'pending' => OrderStatus.placed,
      'confirmed' => OrderStatus.accepted,
      'processing' => OrderStatus.preparing,
      'shipped' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'cancelled' || 'canceled' => OrderStatus.cancelled,
      _ => OrderStatus.unknown,
    };

/// The app's status as the live API spells it — the only values
/// `PATCH /vendor/orders/{id}/status` takes. A turned-down order is
/// `cancelled`; there is no word for why.
String? orderStatusToApi(OrderStatus status) => switch (status) {
      OrderStatus.placed => 'pending',
      OrderStatus.accepted => 'confirmed',
      OrderStatus.preparing => 'processing',
      OrderStatus.ready || OrderStatus.outForDelivery => 'shipped',
      OrderStatus.delivered => 'delivered',
      OrderStatus.cancelled || OrderStatus.rejected => 'cancelled',
      OrderStatus.unknown => null,
    };

/// The step after [status] on the API's path — pending → confirmed →
/// processing → shipped → delivered — or null once it is off it.
OrderStatus? _nextOnApi(OrderStatus status) => switch (status) {
      OrderStatus.placed => OrderStatus.accepted,
      OrderStatus.accepted => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.outForDelivery,
      OrderStatus.ready || OrderStatus.outForDelivery => OrderStatus.delivered,
      _ => null,
    };

/// Dinars as the API writes them (`"9.250"`) in fils.
int _filsOf(Object? value) => ((asDouble(value) ?? 0) * 1000).round();

String _customerNameOf(Map<String, dynamic> json) =>
    asString(asMap(json['address'])['recipient_name']) ??
    asString(asMap(json['customer'])['name']) ??
    asString(asMap(json['user'])['name']) ??
    '';

/// `96551502244` → `•••• 2244`.
String? _masked(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return null;
  return '•••• ${digits.substring(digits.length - 4)}';
}

/// The address as one line, the way the design prints it:
/// `حولي · قطعة 3 · شارع … · مبنى 12`. Parts the customer left out are
/// skipped; the city comes last, the directions after it.
String? _addressLine(Map<String, dynamic> address) {
  String? labelled(String key, String label) => switch (asString(address[key])) {
        final value? => label.tr(args: [value]),
        null => null,
      };

  final parts = [
    ?asString(address['area']),
    ?labelled('block', 'address_block'),
    ?asString(address['street']),
    ?labelled('building', 'address_building'),
    ?labelled('floor', 'address_floor'),
    ?labelled('apartment', 'address_apartment'),
    ?asString(address['city']),
    ?asString(address['additional_directions']),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

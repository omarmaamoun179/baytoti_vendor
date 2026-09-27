import '../../../../core/domain/paged.dart';
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
}

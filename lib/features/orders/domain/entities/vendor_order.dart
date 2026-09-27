import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import 'order_status.dart';

/// A row of the orders list — `GET /vendor/orders` `items`.
class VendorOrderSummary extends Equatable {
  /// Opaque (`ord_2041`), for the details route.
  final String id;

  /// What the family and the customer call it (`BT-2041`).
  final String reference;

  final OrderStatus status;
  final String customerName;
  final int itemCount;
  final int totalFils;
  final FulfilmentMethod fulfilment;
  final DateTime? placedAt;

  const VendorOrderSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.customerName,
    required this.itemCount,
    required this.totalFils,
    required this.fulfilment,
    this.placedAt,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        customerName,
        itemCount,
        totalFils,
        fulfilment,
        placedAt,
      ];
}

/// How many orders each tab holds — the list answer's `counts`, so the chips
/// are right without reading every tab.
class OrderCounts extends Equatable {
  final int all;
  final int fresh;
  final int preparing;
  final int done;

  const OrderCounts({
    this.all = 0,
    this.fresh = 0,
    this.preparing = 0,
    this.done = 0,
  });

  int of(OrderTab tab) => switch (tab) {
        OrderTab.all => all,
        OrderTab.fresh => fresh,
        OrderTab.preparing => preparing,
        OrderTab.done => done,
      };

  @override
  List<Object?> get props => [all, fresh, preparing, done];
}

/// One page of a tab, and every tab's count.
class OrderList extends Equatable {
  final Paged<VendorOrderSummary> page;
  final OrderCounts counts;

  const OrderList({required this.page, required this.counts});

  @override
  List<Object?> get props => [page, counts];
}

class OrderCustomer extends Equatable {
  final String name;

  /// `•••• 2244` — the number itself is not the family's to see.
  final String? phoneMasked;

  /// Empty for a pickup.
  final String? address;

  const OrderCustomer({required this.name, this.phoneMasked, this.address});

  @override
  List<Object?> get props => [name, phoneMasked, address];
}

class OrderLine extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final int lineTotalFils;
  final String? imageUrl;

  const OrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.lineTotalFils,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [productId, name, quantity, lineTotalFils, imageUrl];
}

/// What the family is owed for an order.
class OrderPayout extends Equatable {
  final int grossFils;

  /// Null while the commission model is pending sign-off — the contract
  /// ships it null and the app shows the gross with [note].
  final int? commissionFils;

  final String? note;

  const OrderPayout({required this.grossFils, this.commissionFils, this.note});

  @override
  List<Object?> get props => [grossFils, commissionFils, note];
}

/// `GET /vendor/orders/{id}`.
class VendorOrder extends Equatable {
  final String id;
  final String reference;
  final OrderStatus status;
  final DateTime? placedAt;
  final FulfilmentMethod fulfilment;
  final OrderCustomer customer;
  final List<OrderLine> lines;
  final OrderPayout payout;

  /// What the one advance button sends; null when the order has nowhere
  /// left to go.
  final OrderStatus? nextStatus;

  final bool canReject;

  const VendorOrder({
    required this.id,
    required this.reference,
    required this.status,
    this.placedAt,
    required this.fulfilment,
    required this.customer,
    this.lines = const [],
    required this.payout,
    this.nextStatus,
    this.canReject = false,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        placedAt,
        fulfilment,
        customer,
        lines,
        payout,
        nextStatus,
        canReject,
      ];
}

/// An order's state — the contract's `status`, shared with the customer
/// app: `placed · accepted · preparing · ready · out_for_delivery ·
/// delivered · cancelled · rejected`.
///
/// The server owns the machine: the details answer carries `next_status`,
/// and the app never works out a move for itself.
enum OrderStatus {
  placed('placed', step: 0),
  accepted('accepted', step: 1),
  preparing('preparing', step: 2),
  ready('ready', step: 3),
  outForDelivery('out_for_delivery', step: 3),
  delivered('delivered', step: 4),
  cancelled('cancelled'),
  rejected('rejected'),

  /// A value this build does not know. Drawn neutrally, and offers no move.
  unknown('');

  const OrderStatus(this.wire, {this.step});

  final String wire;

  /// Where the order is on the design's five-segment progress bar (placed
  /// → accepted → preparing → ready → delivered); null once it left the
  /// path. "Out for delivery" shares "ready"'s segment — the design has no
  /// segment of its own for it.
  final int? step;

  /// Number of segments on the progress bar.
  static const int stepCount = 5;

  bool get isClosed =>
      this == delivered || this == cancelled || this == rejected;

  static OrderStatus fromWire(String? value) => values.firstWhere(
        (status) => status.wire == value && status != unknown,
        orElse: () => unknown,
      );
}

/// The orders screen's tabs — the contract's `state` filter.
enum OrderTab {
  all('all'),
  fresh('new'),
  preparing('preparing'),
  done('done');

  const OrderTab(this.wire);

  final String wire;

  /// `/orders?tab=new`; anything else is [all].
  static OrderTab fromQuery(String? value) => values.firstWhere(
        (tab) => tab.wire == value,
        orElse: () => all,
      );
}

enum FulfilmentMethod {
  delivery('delivery'),
  pickup('pickup');

  const FulfilmentMethod(this.wire);

  final String wire;

  /// Unknown reads as [delivery], the case with an address to show.
  static FulfilmentMethod fromWire(String? value) => values.firstWhere(
        (method) => method.wire == value,
        orElse: () => delivery,
      );
}

/// Why a family turns an order down — the `reason` of the reject call.
enum RejectReason {
  outOfStock('out_of_stock'),
  tooBusy('too_busy'),
  cannotDeliver('cannot_deliver'),
  other('other');

  const RejectReason(this.wire);

  final String wire;
}

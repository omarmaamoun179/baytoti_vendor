import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/order_status.dart';

/// How each status is drawn — the design's `ST` table: amber while new,
/// the soft greens while in hand, neutral once closed.
extension OrderStatusStyle on OrderStatus {
  String get labelKey => switch (this) {
        OrderStatus.placed => 'order_status_placed',
        OrderStatus.accepted => 'order_status_accepted',
        OrderStatus.preparing => 'order_status_preparing',
        OrderStatus.ready => 'order_status_ready',
        OrderStatus.outForDelivery => 'order_status_out_for_delivery',
        OrderStatus.delivered => 'order_status_delivered',
        OrderStatus.cancelled => 'order_status_cancelled',
        OrderStatus.rejected => 'order_status_rejected',
        OrderStatus.unknown => 'order_status_unknown',
      };

  Color background(AppPalette p) => switch (this) {
        OrderStatus.placed => p.amberBg,
        OrderStatus.accepted || OrderStatus.preparing => p.accentSoft,
        OrderStatus.ready || OrderStatus.outForDelivery => p.accentSoft2,
        _ => p.surf2,
      };

  Color foreground(AppPalette p) => switch (this) {
        OrderStatus.placed => p.amberInk,
        OrderStatus.accepted ||
        OrderStatus.preparing ||
        OrderStatus.ready ||
        OrderStatus.outForDelivery =>
          p.accentInk,
        _ => p.fg2,
      };

  /// The advance button's label for a move *to* this status.
  String get advanceKey => switch (this) {
        OrderStatus.accepted => 'order_advance_accept',
        OrderStatus.preparing => 'order_advance_prepare',
        OrderStatus.ready => 'order_advance_ready',
        OrderStatus.outForDelivery => 'order_advance_out_for_delivery',
        OrderStatus.delivered => 'order_advance_deliver',
        _ => 'order_advance_generic',
      };

  /// The toast once a move to this status went through.
  String get movedKey => switch (this) {
        OrderStatus.rejected => 'order_moved_rejected',
        _ => 'order_moved',
      };
}

extension FulfilmentLabel on FulfilmentMethod {
  String get labelKey => switch (this) {
        FulfilmentMethod.delivery => 'fulfilment_delivery',
        FulfilmentMethod.pickup => 'fulfilment_pickup',
      };
}

extension OrderTabLabel on OrderTab {
  String get labelKey => switch (this) {
        OrderTab.all => 'orders_tab_all',
        OrderTab.fresh => 'orders_tab_new',
        OrderTab.preparing => 'orders_tab_preparing',
        OrderTab.done => 'orders_tab_done',
      };
}

/// The status as the design's small pill.
class OrderStatusPill extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const OrderStatusPill({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return StatusPill(
      label: status.labelKey.tr(),
      background: status.background(p),
      foreground: status.foreground(p),
      large: large,
    );
  }
}

/// "4 minutes ago", or nothing when the server sent no time.
String orderTimeLabel(BuildContext context, DateTime? placedAt) =>
    placedAt == null ? '' : relativeTimeLabel(context, placedAt);

/// "2 items", pluralised for Arabic's six forms.
String itemCountLabel(int count) => 'order_items'.plural(count);

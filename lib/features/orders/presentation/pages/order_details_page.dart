import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/vendor_order.dart';
import '../cubit/order_details_cubit.dart';
import '../cubit/order_details_state.dart';
import '../widgets/order_action_bar.dart';
import '../widgets/order_customer_card.dart';
import '../widgets/order_header_card.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_status_style.dart';
import '../widgets/reject_order_sheet.dart';

/// V04 — one order: where it stands, who it is for, what is in it, and the
/// one button that moves it a step (accept → prepare → ready → deliver).
///
/// Pops with `true` once a move went through, so whichever list opened it
/// reads itself again.
class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailsCubit>()..load(orderId),
      child: _OrderDetailsView(orderId: orderId),
    );
  }
}

class _OrderDetailsView extends StatelessWidget {
  final String orderId;

  const _OrderDetailsView({required this.orderId});

  Future<void> _reject(BuildContext context) async {
    final rejection = await showRejectOrderSheet(context);
    if (rejection == null || !context.mounted) return;
    context
        .read<OrderDetailsCubit>()
        .reject(rejection.reason, note: rejection.note);
  }

  void _onState(BuildContext context, OrderDetailsState state) {
    final movedTo = state.movedTo;
    if (state.actionStatus == OrderActionStatus.succeeded && movedTo != null) {
      showAppToast(
        context,
        movedTo.movedKey.tr(args: [movedTo.labelKey.tr()]),
      );
    } else if (state.actionStatus == OrderActionStatus.failed) {
      showAppToast(
        context,
        state.errorMessage ?? 'order_status_failed'.tr(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailsCubit, OrderDetailsState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus,
      listener: _onState,
      builder: (context, state) {
        final order = state.order;

        return PopScope(
          canPop: false,
          // Every way out — the header's back, the system gesture — leaves
          // through here, carrying whether anything changed.
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(state.changed);
          },
          child: Scaffold(
            body: Column(
              children: [
                ScreenHeader(
                  kicker: 'kicker_order'.tr(),
                  title: 'title_order'.tr(),
                  showBack: true,
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
            bottomNavigationBar: order == null
                ? null
                : OrderActionBar(
                    order: order,
                    advancing:
                        state.actionStatus == OrderActionStatus.advancing,
                    rejecting:
                        state.actionStatus == OrderActionStatus.rejecting,
                    onAdvance: context.read<OrderDetailsCubit>().advance,
                    onReject: () => _reject(context),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailsState state) {
    final order = state.order;
    if (order != null) return _buildOrder(order);

    if (state.status == OrderDetailsStatus.error) {
      return LoadErrorView(
        message: state.errorMessage ?? 'order_failed'.tr(),
        onRetry: () => context.read<OrderDetailsCubit>().load(orderId),
      );
    }
    return const LoadingView();
  }

  Widget _buildOrder(VendorOrder order) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      children: [
        OrderHeaderCard(order: order),
        SizedBox(height: 12.h),
        OrderCustomerCard(order: order),
        SizedBox(height: 12.h),
        OrderItemsCard(order: order),
      ],
    );
  }
}

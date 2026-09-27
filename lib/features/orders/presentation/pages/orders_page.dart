import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/order_status.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_tabs_strip.dart';

/// V03 — the orders tab: split across the lifecycle states, with a count on
/// each, and a page at a time.
class OrdersPage extends StatelessWidget {
  /// The tab to open on — `/orders?tab=new` from the dashboard.
  final OrderTab initialTab;

  const OrdersPage({super.key, this.initialTab = OrderTab.all});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersCubit>()..load(tab: initialTab),
      child: _OrdersView(initialTab: initialTab),
    );
  }
}

class _OrdersView extends StatefulWidget {
  final OrderTab initialTab;

  const _OrdersView({required this.initialTab});

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  @override
  void didUpdateWidget(_OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab stays alive in the shell; a link that names another tab
    // switches it rather than building a second list.
    if (widget.initialTab != oldWidget.initialTab) {
      context.read<OrdersCubit>().selectTab(widget.initialTab);
    }
  }

  Future<void> _open(String id) async {
    final changed = await context.push<bool>(AppRoutes.order(id));
    if (changed == true && mounted) {
      context.read<OrdersCubit>().load(refresh: true);
    }
  }

  void _onState(BuildContext context, OrdersState state) {
    if (state.status == OrdersStatus.loaded) {
      context.read<OrdersBadgeCubit>().reportCount(state.counts.fresh);
    }
    final message = state.errorMessage;
    if (message != null && state.hasContent) {
      showAppToast(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleChangeListener(
      onChanged: () => context.read<OrdersCubit>().load(refresh: true),
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              kicker: 'kicker_orders'.tr(),
              title: 'title_orders'.tr(),
              actions: const [NotificationBell()],
            ),
            Expanded(
              child: BlocConsumer<OrdersCubit, OrdersState>(
                listener: _onState,
                builder: _buildList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, OrdersState state) {
    final cubit = context.read<OrdersCubit>();

    return RefreshIndicator(
      onRefresh: () => cubit.load(refresh: true),
      child: LazyLoadScrollView(
        isLoading: state.isLoadingMore,
        onEndOfPage: cubit.loadMore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: OrderTabsStrip(
                selected: state.tab,
                counts: state.counts,
                onSelected: cubit.selectTab,
              ),
            ),
            ..._buildContent(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, OrdersState state) {
    if (state.status == OrdersStatus.error) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadErrorView(
            message: state.errorMessage ?? 'orders_failed'.tr(),
            onRetry: context.read<OrdersCubit>().load,
          ),
        ),
      ];
    }
    if (!state.hasContent) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
      ];
    }
    if (state.orders.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: AppIcons.navOrders,
            message: 'orders_empty'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        sliver: SliverList.separated(
          itemCount: state.orders.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final order = state.orders[index];
            return OrderCard(order: order, onTap: () => _open(order.id));
          },
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(child: LoadingView()),
    ];
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/abstract/count_badge_state.dart';
import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../domain/entities/vendor_dashboard.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/recent_orders_card.dart';
import '../widgets/sales_today_card.dart';
import '../widgets/weekly_sales_card.dart';

/// V02 — the family dashboard: today's sales first, then the indicators,
/// the week, and the orders needing action.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  Future<void> _push(BuildContext context, String location) async {
    final changed = await context.push<bool>(location);
    if (changed == true && context.mounted) {
      context.read<DashboardCubit>().load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardCubit, DashboardState>(
          listener: (context, state) {
            final dashboard = state.dashboard;
            if (state.status == DashboardStatus.loaded && dashboard != null) {
              context
                  .read<OrdersBadgeCubit>()
                  .reportCount(dashboard.kpis.newOrders);
            }
            final message = state.errorMessage;
            if (message != null && dashboard != null) {
              showAppToast(context, message, isError: true);
            }
          },
        ),
        // The tab stays alive while orders move elsewhere; when another
        // screen reports a different count of new orders, read again.
        BlocListener<OrdersBadgeCubit, CountBadgeState>(
          listenWhen: (previous, current) => previous.count != current.count,
          listener: (context, badge) {
            final cubit = context.read<DashboardCubit>();
            final shown = cubit.state.dashboard?.kpis.newOrders;
            if (shown != null && shown != badge.count) {
              cubit.load(refresh: true);
            }
          },
        ),
      ],
      child: LocaleChangeListener(
        onChanged: () => context.read<DashboardCubit>().load(refresh: true),
        child: Scaffold(
          body: Column(
            children: [
              ScreenHeader(
                kicker: 'kicker_dashboard'.tr(),
                title: 'title_dashboard'.tr(),
                actions: const [NotificationBell()],
              ),
              Expanded(
                child: BlocBuilder<DashboardCubit, DashboardState>(
                  builder: _buildBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    final cubit = context.read<DashboardCubit>();
    final dashboard = state.dashboard;

    if (dashboard == null) {
      return state.status == DashboardStatus.error
          ? LoadErrorView(
              message: state.errorMessage ?? 'dashboard_failed'.tr(),
              onRetry: cubit.load,
            )
          : const LoadingView();
    }

    return RefreshIndicator(
      onRefresh: () => cubit.load(refresh: true),
      child: _buildContent(context, dashboard),
    );
  }

  Widget _buildContent(BuildContext context, VendorDashboard dashboard) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      children: [
        SalesTodayCard(
          totalFils: dashboard.salesTodayFils,
          change: dashboard.salesChange,
        ),
        SizedBox(height: 12.h),
        KpiGrid(
          kpis: dashboard.kpis,
          onNewOrders: () => context.go(
            '${AppRoutes.orders}?${AppRoutes.tabQuery}=${OrderTab.fresh.wire}',
          ),
          onUnavailable: () => context.go(AppRoutes.products),
        ),
        if (dashboard.week.isNotEmpty) ...[
          SizedBox(height: 12.h),
          WeeklySalesCard(
            week: dashboard.week,
            totalFils: dashboard.weekTotalFils,
          ),
        ],
        SectionHeader(
          title: 'dashboard_needs_action'.tr(),
          actionLabel: 'see_all'.tr(),
          onAction: () => context.go(AppRoutes.orders),
        ),
        RecentOrdersCard(
          orders: dashboard.recentOrders,
          onOpen: (id) => _push(context, AppRoutes.order(id)),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'dashboard_add_product'.tr(),
                height: 48.h,
                labelStyle: AppStrings.text12w800,
                onPressed: () => _push(context, AppRoutes.newProduct),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SecondaryButton(
                label: 'dashboard_new_offer'.tr(),
                height: 48.h,
                background: Theme.of(context).colorScheme.surface,
                onPressed: () => context.go(AppRoutes.offers),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

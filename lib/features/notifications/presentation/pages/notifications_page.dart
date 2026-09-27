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
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/vendor_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';

/// V09 — new orders, status changes, ratings, approvals, stock and
/// exhibition invites. Opening the list reads it: the bell's dot goes, while
/// the rows keep their unread highlight for this visit.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  void _open(BuildContext context, NotificationTarget target) {
    final id = target.id!;
    switch (target.kind) {
      case NotificationTargetKind.order:
        context.push(AppRoutes.order(id));
      case NotificationTargetKind.product:
        context.push(AppRoutes.product(id));
      case NotificationTargetKind.none:
        break;
    }
  }

  void _onState(BuildContext context, NotificationsState state) {
    if (state.markedRead) context.read<NotificationBadgeCubit>().clear();
    final message = state.errorMessage;
    if (message != null && state.hasContent) {
      showAppToast(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            kicker: 'kicker_notifications'.tr(),
            title: 'title_notifications'.tr(),
            showBack: true,
          ),
          Expanded(
            child: BlocConsumer<NotificationsCubit, NotificationsState>(
              listener: _onState,
              builder: (context, state) {
                final cubit = context.read<NotificationsCubit>();

                if (state.status == NotificationsStatus.error) {
                  return LoadErrorView(
                    message:
                        state.errorMessage ?? 'notifications_failed'.tr(),
                    onRetry: cubit.load,
                  );
                }
                if (!state.hasContent) return const LoadingView();

                return RefreshIndicator(
                  onRefresh: () => cubit.load(refresh: true),
                  child: LazyLoadScrollView(
                    isLoading: state.isLoadingMore,
                    onEndOfPage: cubit.loadMore,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: _buildSlivers(context, state),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, NotificationsState state) {
    if (state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: AppIcons.bell,
            message: 'notifications_empty'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
        sliver: SliverList.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final notification = state.items[index];
            final target = notification.target;

            return NotificationTile(
              notification: notification,
              onTap: target.opensSomething
                  ? () => _open(context, target)
                  : null,
            );
          },
        ),
      ),
      if (state.isLoadingMore) const SliverToBoxAdapter(child: LoadingView()),
    ];
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/offer.dart';
import '../cubit/offers_cubit.dart';
import '../cubit/offers_state.dart';
import '../widgets/new_discount_card.dart';
import '../widgets/offer_format.dart';
import '../widgets/offer_tile.dart';

/// V07 — a percentage discount within the platform's limits, and the offers
/// already running.
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OffersCubit>()..load(),
      child: const _OffersView(),
    );
  }
}

class _OffersView extends StatelessWidget {
  const _OffersView();

  Future<void> _pickEnd(BuildContext context, DateTime current) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null && context.mounted) {
      // To the end of the chosen day.
      context.read<OffersCubit>().setEndsAt(
            DateTime(picked.year, picked.month, picked.day, 23, 59),
          );
    }
  }

  Future<void> _delete(BuildContext context, Offer offer) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: AppIcons.navOffers,
      title: 'offer_end_title'.tr(args: [percentLabel(offer.percent)]),
      body: 'offer_end_body'.tr(),
      confirmLabel: 'offer_end'.tr(),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<OffersCubit>().delete(offer);
    }
  }

  void _onState(BuildContext context, OffersState state) {
    switch (state.actionStatus) {
      case OfferActionStatus.created:
        showAppToast(context, 'offer_published'.tr());
      case OfferActionStatus.deleted:
        showAppToast(context, 'offer_ended'.tr());
      case OfferActionStatus.failed:
        showAppToast(
          context,
          state.errorMessage ?? 'offer_create_failed'.tr(),
          isError: true,
        );
      case OfferActionStatus.idle || OfferActionStatus.creating:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleChangeListener(
      onChanged: context.read<OffersCubit>().load,
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              kicker: 'kicker_offers'.tr(),
              title: 'title_offers'.tr(),
            ),
            Expanded(
              child: BlocConsumer<OffersCubit, OffersState>(
                listenWhen: (previous, current) =>
                    previous.actionStatus != current.actionStatus,
                listener: _onState,
                builder: _buildBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OffersState state) {
    final overview = state.overview;
    if (overview != null) return _buildContent(context, state, overview);

    return state.status == OffersStatus.error
        ? LoadErrorView(
            message: state.errorMessage ?? 'offers_failed'.tr(),
            onRetry: context.read<OffersCubit>().load,
          )
        : const LoadingView();
  }

  Widget _buildContent(
    BuildContext context,
    OffersState state,
    OffersOverview overview,
  ) {
    final cubit = context.read<OffersCubit>();

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
        children: [
          NewDiscountCard(
            percent: state.percent,
            limits: overview.limits,
            endsAt: state.endsAt,
            atLimit: overview.atLimit,
            publishing: state.isCreating,
            onStep: cubit.stepPercent,
            onPickEnd: () => _pickEnd(context, state.endsAt),
            onPublish: cubit.publish,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(2.w, 20.h, 2.w, 10.h),
            child: CapsLabel('offers_active'.tr()),
          ),
          if (overview.offers.isEmpty)
            EmptyState(
              icon: AppIcons.navOffers,
              message: 'offers_empty'.tr(),
            )
          else
            for (final offer in overview.offers)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: OfferTile(
                  offer: offer,
                  deleting: state.deletingIds.contains(offer.id),
                  onDelete: () => _delete(context, offer),
                ),
              ),
        ],
      ),
    );
  }
}

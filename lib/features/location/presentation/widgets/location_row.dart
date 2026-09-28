import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/location.dart';
import '../cubit/location_context_cubit.dart';
import '../cubit/location_context_state.dart';

/// The account's location — "Hawalli، Kuwait" — as a row of the account
/// card. Opens the location page, and shows what it saved on the way back.
///
/// Needs a [LocationContextCubit] above it.
class LocationRow extends StatelessWidget {
  const LocationRow({super.key});

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<LocationContextCubit>();
    final saved = await context.push<LocationContext>(AppRoutes.location);
    if (!context.mounted) return;

    if (saved != null) {
      cubit.adopt(saved);
      showAppToast(context, 'location_saved_toast'.tr());
    } else if (cubit.state.status == LocationContextStatus.error) {
      cubit.load();
    }
  }

  String? _value(LocationContextState state) {
    final context = state.context;
    return switch (state.status) {
      LocationContextStatus.initial || LocationContextStatus.loading => null,
      LocationContextStatus.error => 'location_unavailable'.tr(),
      LocationContextStatus.loaded => context == null || !context.isSet
          ? 'location_not_set'.tr()
          : [?context.governorateName, ?context.countryName]
              .join('location_separator'.tr()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            AppIcon(AppIcons.pin, size: 16.r, color: p.fg2),
            SizedBox(width: 10.w),
            Text(
              'account_location'.tr(),
              style: AppStrings.text12w600.c(p.fg),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: BlocBuilder<LocationContextCubit, LocationContextState>(
                builder: (context, state) => Text(
                  _value(state) ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.text12w400Flat.c(
                    state.status == LocationContextStatus.error
                        ? p.bad
                        : p.fg2,
                  ),
                ),
              ),
            ),
            SizedBox(width: 6.w),
            AppIcon(
              AppIcons.chevronForward,
              size: 14.r,
              color: p.fg3,
              mirrorInRtl: true,
            ),
          ],
        ),
      ),
    );
  }
}

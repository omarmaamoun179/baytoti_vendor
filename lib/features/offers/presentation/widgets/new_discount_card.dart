import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/offer.dart';
import 'offer_format.dart';

/// A new store-wide discount: the percentage large, stepped within the
/// platform's limits, when it ends, and the button that publishes it.
class NewDiscountCard extends StatelessWidget {
  final int percent;
  final OfferLimits limits;
  final DateTime endsAt;

  /// The family already runs as many offers as the platform allows.
  final bool atLimit;

  final bool publishing;
  final ValueChanged<int> onStep;
  final VoidCallback onPickEnd;
  final VoidCallback onPublish;

  const NewDiscountCard({
    super.key,
    required this.percent,
    required this.limits,
    required this.endsAt,
    required this.atLimit,
    required this.publishing,
    required this.onStep,
    required this.onPickEnd,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('offers_new_discount'.tr()),
          SizedBox(height: 12.h),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 92.w),
                child: Text(
                  percentLabel(percent),
                  style: AppStrings.text44w800.c(p.accent),
                ),
              ),
              SizedBox(width: 14.w),
              _buildStep(context, '−', -1, percent > limits.minPercent),
              SizedBox(width: 8.w),
              _buildStep(context, '+', 1, percent < limits.maxPercent),
            ],
          ),
          SizedBox(height: 14.h),
          _buildEndRow(context),
          SizedBox(height: 14.h),
          PrimaryButton(
            label: 'offers_publish'.tr(),
            height: 46.h,
            labelStyle: AppStrings.text12w800,
            enabled: !atLimit,
            loading: publishing,
            onPressed: onPublish,
          ),
          SizedBox(height: 10.h),
          Text(
            atLimit
                ? 'offers_at_limit'.tr(args: ['${limits.maxActive}'])
                : 'offers_limits_note'.tr(args: [
                    percentLabel(limits.minPercent),
                    percentLabel(limits.maxPercent),
                  ]),
            style: AppStrings.text105w400Loose.c(atLimit ? p.amberInk : p.fg3),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String sign,
    int direction,
    bool enabled,
  ) {
    final p = context.palette;
    final radius = BorderRadius.circular(12.r);

    return Expanded(
      child: SizedBox(
        height: 46.h,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: p.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => onStep(direction) : null,
            child: Center(
              child: Text(
                sign,
                style: AppStrings.text18w800.c(enabled ? p.accent : p.line2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndRow(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onPickEnd,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.calendar, size: 16.r, color: p.accent),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'offers_ends_on'.tr(args: [dayMonthLabel(context, endsAt)]),
                style: AppStrings.text125w600Flat.c(p.fg),
              ),
            ),
            Text(
              'offers_change'.tr(),
              style: AppStrings.text11w800.c(p.accent),
            ),
          ],
        ),
      ),
    );
  }
}

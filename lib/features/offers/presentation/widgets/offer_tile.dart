import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/offer.dart';
import 'offer_format.dart';

/// A running offer: the percentage on an amber tile, what it covers, until
/// when and how often it has been used, and a close button to end it.
class OfferTile extends StatelessWidget {
  final Offer offer;
  final bool deleting;
  final VoidCallback onDelete;

  const OfferTile({
    super.key,
    required this.offer,
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final endsAt = offer.endsAt;

    return AppCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.amber,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Text(
              percentLabel(offer.percent),
              style: AppStrings.text15w800.c(p.onAccent),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.scopeLabel, style: AppStrings.text125w600.c(p.fg)),
                SizedBox(height: 5.h),
                Text(
                  [
                    if (endsAt != null)
                      'offer_until'.tr(args: [dayMonthLabel(context, endsAt)]),
                    'offer_uses'.plural(offer.redemptionCount),
                  ].join(' · '),
                  style: AppStrings.text105w400.c(p.fg2).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32.r,
            height: 32.r,
            child: deleting
                ? Center(
                    child: SizedBox.square(
                      dimension: 14.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.fg3,
                      ),
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'offer_end'.tr(),
                    onPressed: onDelete,
                    icon: AppIcon(AppIcons.close, size: 14.r, color: p.fg3),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';

extension ProductStateLabel on ProductState {
  String get labelKey => switch (this) {
        ProductState.draft => 'product_state_draft',
        ProductState.pendingReview => 'product_state_pending_review',
        ProductState.published => 'product_state_published',
        ProductState.rejected => 'product_state_rejected',
        ProductState.hidden => 'product_state_hidden',
      };
}

/// A product in the catalogue: its photo, name, stock and state, price —
/// and publishing as one switch. Out of stock is said in amber, since the
/// product has hidden itself.
class ProductRow extends StatelessWidget {
  final VendorProductSummary product;
  final bool toggling;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const ProductRow({
    super.key,
    required this.product,
    required this.toggling,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final out = product.isOutOfStock;
    final stockLine = out
        ? 'product_out_of_stock'.tr()
        : '${'product_stock_count'.tr(args: ['${product.stock}'])} · '
            '${product.state.labelKey.tr()}';

    return AppCard(
      padding: EdgeInsets.all(12.r),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox.square(
              dimension: 56.r,
              child: NetworkPhoto(source: product.imageUrl, iconSize: 17.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.text125w600.c(p.fg),
                ),
                SizedBox(height: 5.h),
                Text(
                  stockLine,
                  style: AppStrings.text105w400.c(out ? p.amberInk : p.fg2),
                ),
                SizedBox(height: 7.h),
                Text(
                  Money.display(product.priceFils),
                  style: AppStrings.text125w800Flat.c(p.fg),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          AppSwitch(
            value: product.isLive,
            busy: toggling,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}

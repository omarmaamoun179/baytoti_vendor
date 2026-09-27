import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';

/// The bar pinned under a screen's content — accept/reject on an order,
/// draft/submit on a product, save on the store profile: `surface` fill,
/// hairline top border, `12px 16px` around its row, lifted clear of the
/// home indicator.
class BottomActionBar extends StatelessWidget {
  final Widget child;

  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surf,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16.w,
          12.h,
          16.w,
          inset > 0 ? inset : 16.h,
        ),
        child: child,
      ),
    );
  }
}

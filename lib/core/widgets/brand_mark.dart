import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';

/// Baytouti's mark: the house drawn in the accent on a white tile with
/// rounded corners and a soft lift — the sign-in screen's logo.
class BrandMark extends StatelessWidget {
  /// The tile's side; the house takes about half of it.
  final double size;

  const BrandMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surf,
        borderRadius: BorderRadius.circular(size * .29),
        boxShadow: [
          BoxShadow(
            color: const Color(0x24000000),
            blurRadius: 18.r,
            offset: Offset(0, 6.r),
          ),
        ],
      ),
      child: AppIcon(AppIcons.house, size: size * .51, color: p.accent),
    );
  }
}

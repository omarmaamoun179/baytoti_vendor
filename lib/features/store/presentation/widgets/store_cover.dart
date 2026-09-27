import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';

/// The family page's cover, with "Change cover" on it. A cover on its way
/// up shows a spinner. Without [onChange] — a store whose cover cannot be
/// saved from the app — it is only the picture.
class StoreCover extends StatelessWidget {
  final String? source;
  final bool uploading;
  final VoidCallback? onChange;

  const StoreCover({
    super.key,
    required this.source,
    required this.uploading,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: uploading ? null : onChange,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 112.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              source == null
                  ? PhotoPlaceholder(iconSize: 24.r, color: p.line2)
                  : NetworkPhoto(source: source, iconSize: 24.r),
              if (uploading)
                ColoredBox(
                  color: p.fg.withValues(alpha: .3),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: p.surf,
                      ),
                    ),
                  ),
                ),
              if (onChange != null)
                PositionedDirectional(
                  bottom: 10.r,
                  end: 10.r,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: p.surf,
                      borderRadius: BorderRadius.circular(9.r),
                      boxShadow: p.cardShadow,
                    ),
                    child: Text(
                      'store_change_cover'.tr(),
                      style: AppStrings.text10w800.c(p.fg),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

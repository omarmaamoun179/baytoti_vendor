import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

/// The sign-up's profile photo (`avatar`), which may be left out: a round
/// tile that opens the gallery, showing the photo once one is chosen, with a
/// line under it to add, change or remove it. Not in the vendor design;
/// built after the customer app's, which the two apps share.
///
/// [error] is the server's refusal of the photo, drawn under it as a
/// field's message is.
class AvatarPicker extends StatelessWidget {
  /// The chosen photo on the device, or null for none.
  final String? path;

  final String? error;

  /// Null while the form is busy.
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  const AvatarPicker({
    super.key,
    required this.path,
    required this.onPick,
    required this.onRemove,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = this.error;
    final size = 88.r;

    return Column(
      children: [
        Semantics(
          button: true,
          label: (path == null ? 'auth_add_photo' : 'auth_change_photo').tr(),
          child: GestureDetector(
            onTap: onPick,
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                children: [
                  _buildPhoto(p, size),
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: _buildBadge(p),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink(
              p,
              path == null ? 'auth_add_photo' : 'auth_change_photo',
              onPick,
            ),
            if (path != null) ...[
              Text('·', style: AppStrings.text115w800.c(p.fg3)),
              _buildLink(p, 'auth_remove_photo', onRemove, color: p.fg2),
            ],
          ],
        ),
        if (error != null)
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppStrings.text105w400.c(p.bad),
          ),
      ],
    );
  }

  Widget _buildPhoto(AppPalette p, double size) {
    final placeholder = ColoredBox(
      color: p.surf,
      child: Center(
        child: AppIcon(AppIcons.user, size: size * .42, color: p.fg3),
      ),
    );
    final path = this.path;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: error == null ? p.line : p.bad),
      ),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: path == null
          ? placeholder
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }

  /// The accent `+` at the tile's corner, cut out of the page by a ring of
  /// its background.
  Widget _buildBadge(AppPalette p) => Container(
        width: 28.r,
        height: 28.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.accent,
          shape: BoxShape.circle,
          border: Border.all(color: p.bg, width: 2),
        ),
        child: AppIcon(AppIcons.plus, size: 14.r, color: p.onAccent),
      );

  Widget _buildLink(
    AppPalette p,
    String key,
    VoidCallback? onTap, {
    Color? color,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          child: Text(
            key.tr(),
            style: AppStrings.text115w800.c(
              onTap == null ? p.fg3 : color ?? p.accent,
            ),
          ),
        ),
      );
}

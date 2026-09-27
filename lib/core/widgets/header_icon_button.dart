import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';

/// The header's 34×34 bordered button — back, and the bell.
///
/// [dot] pins the design's small amber dot to the top-end corner: something
/// unread behind the bell.
class HeaderIconButton extends StatelessWidget {
  final String icon;
  final double iconSize;
  final VoidCallback? onPressed;
  final bool mirrorInRtl;
  final bool dot;
  final String? semanticLabel;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.iconSize,
    this.onPressed,
    this.mirrorInRtl = false,
    this.dot = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(10.r);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 34.r,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(color: p.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: Center(
                    child: AppIcon(
                      icon,
                      size: iconSize,
                      color: p.fg,
                      mirrorInRtl: mirrorInRtl,
                    ),
                  ),
                ),
              ),
            ),
            if (dot)
              PositionedDirectional(
                top: -2.r,
                end: -2.r,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: p.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Back, drawn as the design's chevron and mirrored for RTL. Pops by
/// default, through `maybePop` so a screen's `PopScope` is asked first.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: AppIcons.chevronBack,
      iconSize: 15.r,
      mirrorInRtl: true,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

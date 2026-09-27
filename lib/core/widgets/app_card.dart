import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';

/// The design's card: `surface` fill, hairline `divider` border, 16px
/// radius and the one `--bt-card` shadow.
///
/// [onTap] makes the whole card the target, the way the design's order and
/// notification cards are `<button>`s.
class AppCard extends StatelessWidget {
  final Widget child;

  /// Defaults to `14px` all round.
  final EdgeInsetsGeometry? padding;

  final double? radius;
  final Color? color;
  final VoidCallback? onTap;

  /// Clips the content to the card's corners — for a card whose rows carry
  /// their own dividers and tap ripples edge to edge.
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.onTap,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = BorderRadius.circular(radius ?? 16.r);

    final content = Padding(
      padding: padding ?? EdgeInsets.all(14.r),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: p.cardShadow,
      ),
      child: Material(
        color: color ?? p.surf,
        clipBehavior: clip || onTap != null ? Clip.antiAlias : Clip.none,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: p.line),
        ),
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

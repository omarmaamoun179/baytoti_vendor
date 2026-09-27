import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'size_config.dart';

/// Initialises [ScreenUtil] from the *inherited* [MediaQuery].
///
/// Stands in for `ScreenUtilInit`, which sizes against `View.of(context)` —
/// the real window — and ignores its own `useInheritedMediaQuery` flag (a dead
/// field in flutter_screenutil 5.9.3). On a device the two agree, but under
/// `device_preview` the simulated screen reaches the tree only as a
/// [MediaQuery], so `ScreenUtilInit` would scale type to the host window while
/// the layout followed the simulated phone.
///
/// [ScreenUtil]'s numbers live in a global singleton, so a size change is
/// invisible to widgets that have already built — after one, the subtree is
/// marked dirty, which is what `ScreenUtilInit` does too.
class ScreenUtilScope extends StatefulWidget {
  final Widget child;

  const ScreenUtilScope({super.key, required this.child});

  @override
  State<ScreenUtilScope> createState() => _ScreenUtilScopeState();
}

class _ScreenUtilScopeState extends State<ScreenUtilScope> {
  static const Size _designSize = Size(
    SizeConfig.designWidth,
    SizeConfig.designHeight,
  );

  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);

    // Skips the first pass: nothing has built against the old scale yet.
    if (_lastSize != null && _lastSize != size) {
      // After the frame, because markNeedsBuild is illegal during a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(_markDirty);
      });
    }
    _lastSize = size;
  }

  void _markDirty(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markDirty);
  }

  /// Scales type by the smaller of the two axes, the same factor `.r` gives
  /// a box.
  ///
  /// Boxes scale too (`.w`, `.h`, `.r`), so type grows and shrinks with the
  /// slot it sits in. Taking the smaller axis keeps a caption from outgrowing
  /// a row whose height scaled less than its width — a short, wide screen.
  static double _scaleWithLayout(num fontSize, ScreenUtil instance) =>
      fontSize * math.min(instance.scaleWidth, instance.scaleHeight);

  @override
  Widget build(BuildContext context) {
    ScreenUtil.configure(
      data: MediaQuery.of(context),
      designSize: _designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: _scaleWithLayout,
    );
    return widget.child;
  }
}

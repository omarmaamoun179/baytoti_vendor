import 'package:flutter/material.dart';

extension MediaQueryValues on BuildContext {
  // Each accessor subscribes only to its specific MediaQuery aspect,
  // so widgets rebuild only when that value actually changes.
  double get height => MediaQuery.sizeOf(this).height;
  double get width => MediaQuery.sizeOf(this).width;
  double get toPadding => MediaQuery.viewPaddingOf(this).top;
  double get bottom => MediaQuery.viewInsetsOf(this).bottom;
  double get bottomPadding => MediaQuery.viewPaddingOf(this).bottom;
  // padding (not viewPadding): excludes areas covered by viewInsets (keyboard).
  // Matches MediaQuery.of(context).padding.bottom — collapses to 0 when the
  // keyboard is open, so it won't double-pad above a keyboard-aware bottom bar.
  double get paddingBottom => MediaQuery.paddingOf(this).bottom;
}

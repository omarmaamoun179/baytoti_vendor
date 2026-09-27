import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The design reference frame, and a thin wrapper over `flutter_screenutil`
/// for code that reads better as a call than an extension.
///
/// Layout scales with the screen through screenutil's extensions — `16.w`
/// for widths and horizontal space, `12.h` for vertical space and heights,
/// `12.r` for radii and square boxes, `13.sp` for type (which [AppStrings]
/// already applies). All of them measure against [designWidth] ×
/// [designHeight], the iPhone frame the Baytouti design is drawn in.
///
/// Requires [ScreenUtilScope] above the widget tree — wired up in `app.dart`.
class SizeConfig {
  SizeConfig._();

  /// The design's device frame (`hint-size="402px,874px"`).
  static const double designWidth = 402;
  static const double designHeight = 874;

  static double get screenWidth => 1.sw;
  static double get screenHeight => 1.sh;

  /// Width scaled against the design width.
  static double w(double width) => width.w;

  /// Height scaled against the design height.
  static double h(double height) => height.h;

  /// Font size, scaled against the smaller of the two axes.
  static double sp(double size) => size.sp;

  /// Corner radius or a square box, scaled against the smaller axis.
  static double r(double radius) => radius.r;
}

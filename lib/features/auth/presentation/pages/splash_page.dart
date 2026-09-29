import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/caps_label.dart';
import '../widgets/splash_mark.dart';
import '../widgets/splash_timeline.dart';

/// `/splash` — the design's splash: the mark drawn on the vendor app's
/// amber, the shop awning dropping over the door, the name rising under it,
/// and a bar that fills until the app moves on after
/// [SplashTimeline.length], to the dashboard or sign-in. The session was
/// resolved in `bootstrap` before the first frame, so nothing is waited on
/// here. A tap skips it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: SplashTimeline.length)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _leave();
      })
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    _clock.stop();

    final signedIn = sl<SessionNotifier>().isAuthenticated;
    context.go(signedIn ? AppRoutes.dashboard : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.palette.brandGround,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _leave,
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) =>
                _buildFrame(context, SplashTimeline.secondsOf(_clock)),
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(BuildContext context, double seconds) {
    final white = context.palette.onAccent;

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SplashMark(seconds: seconds, size: 190.r),
              _fadeUp(
                seconds,
                SplashTimeline.titleAt,
                top: 6.h,
                // Not tracked, unlike the design: spacing pulls Arabic's
                // joined letters apart.
                Text(
                  'brand_wordmark'.tr(),
                  style: AppStrings.text46w800.c(white),
                ),
              ),
              _fadeUp(
                seconds,
                SplashTimeline.capsAt,
                top: 12.h,
                CapsLabel(
                  'splash_caps'.tr(),
                  color: white.withValues(alpha: .8),
                  tracking: .34,
                ),
              ),
              _fadeUp(
                seconds,
                SplashTimeline.taglineAt,
                top: 18.h,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    'splash_tagline'.tr(),
                    textAlign: TextAlign.center,
                    style: AppStrings.text13w600Loose.c(white),
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 70.h, child: _buildProgress(context, seconds)),
        ],
      ),
    );
  }

  /// `btFadeUp`: in from 12 below.
  Widget _fadeUp(
    double seconds,
    double start,
    Widget child, {
    required double top,
  }) {
    final shown = SplashTimeline.eased(
      SplashTimeline.fadeUp,
      seconds,
      start,
      SplashTimeline.fadeFor,
    );

    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Opacity(
        opacity: shown.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12.h * (1 - shown)),
          child: child,
        ),
      ),
    );
  }

  /// `btBar`: fills from the start side over three seconds.
  Widget _buildProgress(BuildContext context, double seconds) {
    final white = context.palette.onAccent;
    final radius = BorderRadius.circular(3.r);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: 120.w,
        height: 3.h,
        color: white.withValues(alpha: .28),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: SplashTimeline.progress(
            seconds,
            SplashTimeline.barAt,
            SplashTimeline.barFor,
          ),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: white, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
